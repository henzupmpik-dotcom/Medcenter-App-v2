import 'dart:convert';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/security/key_generator.dart';

class AuditLogger {
  AuditLogger._();
  static final AuditLogger instance = AuditLogger._();

  Future<void> log({
    required String action,
    String? tableName,
    String? recordId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    await DatabaseHelper.instance.insert('audit_log', {
      'id': KeyGenerator.uuid(),
      'user_id': AuthService.instance.currentUser?.id,
      'device_id': ClinicConfig.instance.deviceId,
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'old_value': oldValue != null ? jsonEncode(oldValue) : null,
      'new_value': newValue != null ? jsonEncode(newValue) : null,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
