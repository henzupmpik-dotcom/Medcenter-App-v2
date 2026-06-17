import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/audit_logger.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/core/sync/sync_queue.dart';
import 'package:medcenter/shared/models/consultation_model.dart';

class ConsultationRepository {
  ConsultationRepository._();
  static final ConsultationRepository instance = ConsultationRepository._();

  final _db = DatabaseHelper.instance;

  Future<List<ConsultationModel>> getForPatient(String patientId) async {
    final rows = await _db.rawQuery(
      '''SELECT c.*, u.name as doctor_name,
                p.full_name as patient_name, p.file_number as patient_file_number
         FROM consultations c
         LEFT JOIN users u ON u.id = c.user_id
         LEFT JOIN patients p ON p.id = c.patient_id
         WHERE c.patient_id = ? AND c.is_deleted = 0
         ORDER BY c.date DESC''',
      [patientId],
    );
    return rows.map(ConsultationModel.fromMap).toList();
  }

  Future<ConsultationModel?> getById(String id) async {
    final rows = await _db.rawQuery(
      '''SELECT c.*, u.name as doctor_name,
                p.full_name as patient_name, p.file_number as patient_file_number
         FROM consultations c
         LEFT JOIN users u ON u.id = c.user_id
         LEFT JOIN patients p ON p.id = c.patient_id
         WHERE c.id = ? AND c.is_deleted = 0''',
      [id],
    );
    if (rows.isEmpty) return null;
    return ConsultationModel.fromMap(rows.first);
  }

  Future<List<ConsultationModel>> getRecent({int limit = 20}) async {
    final rows = await _db.rawQuery(
      '''SELECT c.*, u.name as doctor_name,
                p.full_name as patient_name, p.file_number as patient_file_number
         FROM consultations c
         LEFT JOIN users u ON u.id = c.user_id
         LEFT JOIN patients p ON p.id = c.patient_id
         WHERE c.is_deleted = 0
         ORDER BY c.date DESC
         LIMIT ?''',
      [limit],
    );
    return rows.map(ConsultationModel.fromMap).toList();
  }

  Future<ConsultationModel> create({
    required String patientId,
    required String date,
    String? chiefComplaint,
    String? history,
    String? examination,
    String? diagnosis,
    String? icd10Code,
    String? treatmentPlan,
    String? followUpDate,
    String? notes,
    VitalsModel? vitals,
  }) async {
    final id = KeyGenerator.uuid();
    final now = DateTime.now().toIso8601String();
    final config = ClinicConfig.instance;
    final doctor = AuthService.instance.currentUser!;

    final consultation = ConsultationModel(
      id: id,
      patientId: patientId,
      userId: doctor.id,
      date: date,
      chiefComplaint: chiefComplaint,
      history: history,
      examination: examination,
      diagnosis: diagnosis,
      icd10Code: icd10Code,
      treatmentPlan: treatmentPlan,
      followUpDate: followUpDate,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      syncVersion: 1,
      deviceId: config.deviceId,
    );

    await _db.insert('consultations', consultation.toMap());

    if (vitals != null) {
      await _db.insert('vitals', vitals.toMap());
    }

    await SyncQueueManager.instance.enqueue(
      tableName: 'consultations',
      recordId: id,
      operation: 'INSERT',
      payload: consultation.toMap(),
      syncVersion: 1,
    );

    await AuditLogger.instance.log(
      action: 'CREATE',
      tableName: 'consultations',
      recordId: id,
      newValue: consultation.toMap(),
    );

    return consultation;
  }

  Future<VitalsModel?> getVitalsForConsultation(String consultationId) async {
    final rows = await _db.query(
      'vitals',
      where: 'consultation_id = ?',
      whereArgs: [consultationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VitalsModel.fromMap(rows.first);
  }

  Future<List<VitalsModel>> getVitalsHistory(String patientId) async {
    final rows = await _db.query(
      'vitals',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'recorded_at DESC',
      limit: 20,
    );
    return rows.map(VitalsModel.fromMap).toList();
  }
}
