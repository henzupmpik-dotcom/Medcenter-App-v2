import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/audit_logger.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/core/sync/sync_queue.dart';
import 'package:medcenter/shared/models/appointment_model.dart';
import 'package:medcenter/shared/utils/number_generator.dart';

class AppointmentRepository {
  AppointmentRepository._();
  static final AppointmentRepository instance = AppointmentRepository._();

  final _db = DatabaseHelper.instance;

  static const _joinSql = '''
    SELECT a.*,
           p.full_name as patient_name,
           p.file_number as patient_file_number,
           p.phone as patient_phone,
           u.name as doctor_name
    FROM appointments a
    LEFT JOIN patients p ON p.id = a.patient_id
    LEFT JOIN users u ON u.id = a.doctor_id
  ''';

  Future<List<AppointmentModel>> getForDate(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await _db.rawQuery(
      '$_joinSql WHERE date(a.scheduled_at) = ? AND a.is_deleted = 0 ORDER BY a.scheduled_at ASC',
      [dateStr],
    );
    return rows.map(AppointmentModel.fromMap).toList();
  }

  Future<List<AppointmentModel>> getForPatient(String patientId) async {
    final rows = await _db.rawQuery(
      '$_joinSql WHERE a.patient_id = ? AND a.is_deleted = 0 ORDER BY a.scheduled_at DESC',
      [patientId],
    );
    return rows.map(AppointmentModel.fromMap).toList();
  }

  Future<List<AppointmentModel>> getForDoctor(String doctorId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await _db.rawQuery(
      '$_joinSql WHERE a.doctor_id = ? AND date(a.scheduled_at) = ? AND a.is_deleted = 0 ORDER BY a.scheduled_at ASC',
      [doctorId, dateStr],
    );
    return rows.map(AppointmentModel.fromMap).toList();
  }

  Future<AppointmentModel> create({
    required String patientId,
    required String doctorId,
    required DateTime scheduledAt,
    int durationMinutes = 30,
    String? reason,
    String? notes,
  }) async {
    final id = KeyGenerator.uuid();
    final appNumber = await NumberGenerator.instance.nextAppointmentNumber();
    final now = DateTime.now().toIso8601String();
    final config = ClinicConfig.instance;
    final currentUser = AuthService.instance.currentUser!;

    final appointment = AppointmentModel(
      id: id,
      appointmentNumber: appNumber,
      patientId: patientId,
      doctorId: doctorId,
      scheduledAt: scheduledAt.toIso8601String(),
      durationMinutes: durationMinutes,
      status: 'booked',
      reason: reason,
      notes: notes,
      createdBy: currentUser.id,
      createdAt: now,
      updatedAt: now,
      syncVersion: 1,
      deviceId: config.deviceId,
    );

    await _db.insert('appointments', appointment.toMap());

    await SyncQueueManager.instance.enqueue(
      tableName: 'appointments',
      recordId: id,
      operation: 'INSERT',
      payload: appointment.toMap(),
      syncVersion: 1,
    );

    await AuditLogger.instance.log(
      action: 'CREATE',
      tableName: 'appointments',
      recordId: id,
      newValue: appointment.toMap(),
    );

    return appointment;
  }

  Future<void> updateStatus(String id, String status) async {
    final now = DateTime.now().toIso8601String();
    final rows = await _db.query('appointments', where: 'id = ?', whereArgs: [id]);
    final sv = (rows.isNotEmpty ? rows.first['sync_version'] as int? : 0) ?? 0;
    await _db.update(
      'appointments',
      {'status': status, 'updated_at': now, 'sync_version': sv + 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await SyncQueueManager.instance.enqueue(
      tableName: 'appointments',
      recordId: id,
      operation: 'UPDATE',
      payload: {'id': id, 'status': status, 'updated_at': now, 'sync_version': sv + 1},
      syncVersion: sv + 1,
    );
    await AuditLogger.instance.log(
      action: 'STATUS_UPDATE',
      tableName: 'appointments',
      recordId: id,
      newValue: {'status': status},
    );
  }

  Future<void> cancel(String id) => updateStatus(id, 'cancelled');
}
