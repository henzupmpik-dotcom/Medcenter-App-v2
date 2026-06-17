import 'dart:convert';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/key_generator.dart';

class ConflictResolver {
  ConflictResolver._();
  static final ConflictResolver instance = ConflictResolver._();

  final _db = DatabaseHelper.instance;

  /// Append-only tables — never overwrite, always insert
  static const _appendOnly = {'consultations', 'prescriptions', 'invoices', 'payments', 'audit_log'};

  Future<void> applyChange(Map<String, dynamic> change) async {
    final table = change['table_name'] as String;
    final recordId = change['record_id'] as String;
    final operation = change['operation'] as String;
    final incomingVersion = change['sync_version'] as int;
    final payload = jsonDecode(change['payload'] as String) as Map<String, dynamic>;

    if (operation == 'DELETE') {
      await _handleDelete(table, recordId, payload, incomingVersion);
      return;
    }

    if (_appendOnly.contains(table) && operation == 'INSERT') {
      // Just insert — don't overwrite
      try {
        await _db.insert(table, payload);
      } catch (_) {} // Duplicate — already have it
      return;
    }

    // Check existing record
    final existing = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [recordId],
      limit: 1,
    );

    if (existing.isEmpty) {
      // No local record — insert
      await _db.insert(table, payload);
      return;
    }

    final localVersion = existing.first['sync_version'] as int? ?? 0;
    final localUpdatedAt = existing.first['updated_at'] as String? ?? '';
    final incomingUpdatedAt = payload['updated_at'] as String? ?? '';

    // Conflict resolution: higher version wins; tie → newer timestamp wins
    final incomingWins = incomingVersion > localVersion ||
        (incomingVersion == localVersion &&
            incomingUpdatedAt.compareTo(localUpdatedAt) > 0);

    if (incomingWins) {
      // Save losing version to conflicts log
      await _db.insert('sync_conflicts', {
        'id': KeyGenerator.uuid(),
        'table_name': table,
        'record_id': recordId,
        'winning_payload': jsonEncode(payload),
        'losing_payload': jsonEncode(existing.first),
        'resolved_at': DateTime.now().toIso8601String(),
        'device_id': ClinicConfig.instance.deviceId,
      });
      await _db.update(table, payload, where: 'id = ?', whereArgs: [recordId]);
    }
    // If local wins, do nothing
  }

  Future<void> _handleDelete(
    String table,
    String recordId,
    Map<String, dynamic> payload,
    int incomingVersion,
  ) async {
    await _db.update(
      table,
      {'is_deleted': 1, 'sync_version': incomingVersion},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }
}
