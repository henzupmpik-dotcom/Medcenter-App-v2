import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/audit_logger.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/core/sync/sync_queue.dart';
import 'package:medcenter/shared/models/prescription_model.dart';
import 'package:medcenter/shared/utils/number_generator.dart';

class PrescriptionRepository {
  PrescriptionRepository._();
  static final PrescriptionRepository instance = PrescriptionRepository._();

  final _db = DatabaseHelper.instance;

  Future<List<PrescriptionItemModel>> _getItems(String prescriptionId) async {
    final rows = await _db.query(
      'prescription_items',
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
    );
    return rows.map(PrescriptionItemModel.fromMap).toList();
  }

  Future<List<PrescriptionModel>> getForPatient(String patientId) async {
    final rows = await _db.rawQuery(
      '''SELECT p.*, u.name as doctor_name,
                pt.full_name as patient_name, pt.file_number as patient_file_number
         FROM prescriptions p
         LEFT JOIN users u ON u.id = p.doctor_id
         LEFT JOIN patients pt ON pt.id = p.patient_id
         WHERE p.patient_id = ? AND p.is_deleted = 0
         ORDER BY p.date DESC''',
      [patientId],
    );

    final List<PrescriptionModel> result = [];
    for (final row in rows) {
      final items = await _getItems(row['id'] as String);
      result.add(PrescriptionModel.fromMap(row, items: items));
    }
    return result;
  }

  Future<PrescriptionModel?> getById(String id) async {
    final rows = await _db.rawQuery(
      '''SELECT p.*, u.name as doctor_name,
                pt.full_name as patient_name, pt.file_number as patient_file_number
         FROM prescriptions p
         LEFT JOIN users u ON u.id = p.doctor_id
         LEFT JOIN patients pt ON pt.id = p.patient_id
         WHERE p.id = ?''',
      [id],
    );
    if (rows.isEmpty) return null;
    final items = await _getItems(id);
    return PrescriptionModel.fromMap(rows.first, items: items);
  }

  Future<PrescriptionModel> create({
    required String patientId,
    String? consultationId,
    required List<PrescriptionItemModel> items,
    String? notes,
    bool isRepeat = false,
    String? doctorId,
  }) async {
    final id = KeyGenerator.uuid();
    final rxNumber = await NumberGenerator.instance.nextPrescriptionNumber();
    final now = DateTime.now().toIso8601String();
    final config = ClinicConfig.instance;
    final doctor = AuthService.instance.currentUser;
    final resolvedDoctorId = doctorId ?? doctor?.id ?? '';

    final prescription = PrescriptionModel(
      id: id,
      prescriptionNumber: rxNumber,
      patientId: patientId,
      consultationId: consultationId,
      doctorId: resolvedDoctorId,
      date: now.substring(0, 10),
      notes: notes,
      isRepeat: isRepeat,
      createdAt: now,
      updatedAt: now,
      syncVersion: 1,
      deviceId: config.deviceId,
    );

    await _db.insert('prescriptions', prescription.toMap());

    final List<PrescriptionItemModel> itemModels = [];
    for (final item in items) {
      // item is already a PrescriptionItemModel from V2 form
      final itemModel = PrescriptionItemModel(
        id: item.id.isEmpty ? KeyGenerator.uuid() : item.id,
        prescriptionId: id,
        medicationName: item.medicationName,
        dosage: item.dosage,
        frequency: item.frequency,
        duration: item.duration,
        route: item.route,       // V2
        refills: item.refills,   // V2
        instructions: item.instructions,
        quantity: item.quantity,
      );
      await _db.insert('prescription_items', itemModel.toMap());
      itemModels.add(itemModel);
    }

    await SyncQueueManager.instance.enqueue(
      tableName: 'prescriptions',
      recordId: id,
      operation: 'INSERT',
      payload: prescription.toMap(),
      syncVersion: 1,
    );

    await AuditLogger.instance.log(
      action: 'CREATE',
      tableName: 'prescriptions',
      recordId: id,
      newValue: prescription.toMap(),
    );

    return PrescriptionModel.fromMap(prescription.toMap(), items: itemModels);
  }

  Future<void> cancel(String id) async {
    final now = DateTime.now().toIso8601String();
    await _db.update(
      'prescriptions',
      {'status': 'cancelled', 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    await AuditLogger.instance.log(
      action: 'CANCEL',
      tableName: 'prescriptions',
      recordId: id,
    );
  }
}
