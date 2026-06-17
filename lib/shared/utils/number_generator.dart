import 'package:medcenter/core/database/database_helper.dart';

class NumberGenerator {
  NumberGenerator._();
  static final NumberGenerator instance = NumberGenerator._();

  final _db = DatabaseHelper.instance;

  /// PAT-000001 (never resets)
  Future<String> nextPatientNumber() async {
    final n = await _db.nextCounter('patient');
    return 'PAT-${n.toString().padLeft(6, '0')}';
  }

  /// APP-2026-0001 (yearly)
  Future<String> nextAppointmentNumber() async {
    final year = DateTime.now().year;
    final n = await _db.nextCounter('appointment_$year');
    return 'APP-$year-${n.toString().padLeft(4, '0')}';
  }

  /// INV-2026-0001 (yearly)
  Future<String> nextInvoiceNumber() async {
    final year = DateTime.now().year;
    final n = await _db.nextCounter('invoice_$year');
    return 'INV-$year-${n.toString().padLeft(4, '0')}';
  }

  /// REC-2026-0001 (yearly)
  Future<String> nextReceiptNumber() async {
    final year = DateTime.now().year;
    final n = await _db.nextCounter('receipt_$year');
    return 'REC-$year-${n.toString().padLeft(4, '0')}';
  }

  /// RX-2026-0001 (yearly)
  Future<String> nextPrescriptionNumber() async {
    final year = DateTime.now().year;
    final n = await _db.nextCounter('prescription_$year');
    return 'RX-$year-${n.toString().padLeft(4, '0')}';
  }

  /// LAB-2026-0001 (yearly)
  Future<String> nextLabNumber() async {
    final year = DateTime.now().year;
    final n = await _db.nextCounter('lab_$year');
    return 'LAB-$year-${n.toString().padLeft(4, '0')}';
  }
}
