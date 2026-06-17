import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/audit_logger.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/core/sync/sync_queue.dart';
import 'package:medcenter/shared/models/patient_model.dart';
import 'package:medcenter/shared/utils/number_generator.dart';

class PatientRepository {
  PatientRepository._();
  static final PatientRepository instance = PatientRepository._();

  final _db = DatabaseHelper.instance;

  Future<List<PatientModel>> getAll({bool includeArchived = false}) async {
    final rows = await _db.query(
      'patients',
      where: includeArchived ? 'is_deleted = 0' : 'is_archived = 0 AND is_deleted = 0',
      orderBy: 'full_name ASC',
    );
    return rows.map(PatientModel.fromMap).toList();
  }

  Future<PatientModel?> getById(String id) async {
    final rows = await _db.query(
      'patients',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PatientModel.fromMap(rows.first);
  }

  Future<List<PatientModel>> search(String query) async {
    final q = '%$query%';
    final rows = await _db.rawQuery(
      '''SELECT * FROM patients
         WHERE is_deleted = 0 AND (
           full_name LIKE ? OR
           file_number LIKE ? OR
           phone LIKE ? OR
           national_id LIKE ?
         )
         ORDER BY full_name ASC
         LIMIT 50''',
      [q, q, q, q],
    );
    return rows.map(PatientModel.fromMap).toList();
  }

  Future<PatientModel> create({
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? nationalId,
    String? address,
    String? phone,
    String? email,
    String? nextOfKinName,
    String? nextOfKinPhone,
    String? nextOfKinRelation,
    String? photoPath,
    String? bloodGroup,
  }) async {
    final id = KeyGenerator.uuid();
    final fileNumber = await NumberGenerator.instance.nextPatientNumber();
    final now = DateTime.now().toIso8601String();
    final config = ClinicConfig.instance;
    final currentUser = AuthService.instance.currentUser;

    final patient = PatientModel(
      id: id,
      fileNumber: fileNumber,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      nationalId: nationalId,
      address: address,
      phone: phone,
      email: email,
      nextOfKinName: nextOfKinName,
      nextOfKinPhone: nextOfKinPhone,
      nextOfKinRelation: nextOfKinRelation,
      photoPath: photoPath,
      bloodGroup: bloodGroup,
      createdBy: currentUser?.id,
      createdAt: now,
      updatedAt: now,
      syncVersion: 1,
      deviceId: config.deviceId,
    );

    await _db.insert('patients', patient.toMap());

    await SyncQueueManager.instance.enqueue(
      tableName: 'patients',
      recordId: id,
      operation: 'INSERT',
      payload: patient.toMap(),
      syncVersion: 1,
    );

    await AuditLogger.instance.log(
      action: 'CREATE',
      tableName: 'patients',
      recordId: id,
      newValue: patient.toMap(),
    );

    return patient;
  }

  Future<PatientModel> update(PatientModel patient) async {
    final oldRows = await _db.query('patients', where: 'id = ?', whereArgs: [patient.id]);
    final updated = patient.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
      syncVersion: patient.syncVersion + 1,
    );

    await _db.update('patients', updated.toMap(),
        where: 'id = ?', whereArgs: [patient.id]);

    await SyncQueueManager.instance.enqueue(
      tableName: 'patients',
      recordId: patient.id,
      operation: 'UPDATE',
      payload: updated.toMap(),
      syncVersion: updated.syncVersion,
    );

    await AuditLogger.instance.log(
      action: 'UPDATE',
      tableName: 'patients',
      recordId: patient.id,
      oldValue: oldRows.isNotEmpty ? oldRows.first : null,
      newValue: updated.toMap(),
    );

    return updated;
  }

  Future<void> archive(String id) async {
    final now = DateTime.now().toIso8601String();
    await _db.update(
      'patients',
      {'is_archived': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    await AuditLogger.instance.log(
      action: 'ARCHIVE',
      tableName: 'patients',
      recordId: id,
    );
  }
}
