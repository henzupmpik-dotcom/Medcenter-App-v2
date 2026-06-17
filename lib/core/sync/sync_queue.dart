import 'dart:convert';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/key_generator.dart';

class SyncQueueManager {
  SyncQueueManager._();
  static final SyncQueueManager instance = SyncQueueManager._();

  final _db = DatabaseHelper.instance;

  Future<void> enqueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
    required int syncVersion,
  }) async {
    final config = ClinicConfig.instance;
    await _db.insert('sync_queue', {
      'id': KeyGenerator.uuid(),
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'payload': jsonEncode(payload),
      'device_id': config.deviceId,
      'sync_version': syncVersion,
      'created_at': DateTime.now().toIso8601String(),
      'synced_at': null,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingChanges() async {
    return await _db.query(
      'sync_queue',
      where: 'synced_at IS NULL',
      orderBy: 'created_at ASC',
      limit: 200,
    );
  }

  Future<void> markSynced(String id) async {
    await _db.update(
      'sync_queue',
      {'synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
