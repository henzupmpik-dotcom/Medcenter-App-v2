import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/audit_logger.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/core/sync/sync_queue.dart';
import 'package:medcenter/shared/models/billing_model.dart';
import 'package:medcenter/shared/utils/number_generator.dart';

class BillingRepository {
  BillingRepository._();
  static final BillingRepository instance = BillingRepository._();

  final _db = DatabaseHelper.instance;

  Future<List<InvoiceItemModel>> _getItems(String invoiceId) async {
    final rows = await _db.query('invoice_items',
        where: 'invoice_id = ?', whereArgs: [invoiceId]);
    return rows.map(InvoiceItemModel.fromMap).toList();
  }

  Future<List<PaymentModel>> _getPayments(String invoiceId) async {
    final rows = await _db.query('payments',
        where: 'invoice_id = ?', whereArgs: [invoiceId], orderBy: 'paid_at ASC');
    return rows.map(PaymentModel.fromMap).toList();
  }

  Future<List<InvoiceModel>> getForPatient(String patientId) async {
    final rows = await _db.rawQuery(
      '''SELECT i.*, p.full_name as patient_name, p.file_number as patient_file_number
         FROM invoices i
         LEFT JOIN patients p ON p.id = i.patient_id
         WHERE i.patient_id = ? AND i.is_deleted = 0
         ORDER BY i.date DESC''',
      [patientId],
    );
    final List<InvoiceModel> result = [];
    for (final row in rows) {
      final id = row['id'] as String;
      result.add(InvoiceModel.fromMap(row,
          items: await _getItems(id), payments: await _getPayments(id)));
    }
    return result;
  }

  Future<List<InvoiceModel>> getUnpaid() async {
    final rows = await _db.rawQuery(
      '''SELECT i.*, p.full_name as patient_name, p.file_number as patient_file_number
         FROM invoices i
         LEFT JOIN patients p ON p.id = i.patient_id
         WHERE i.status != 'paid' AND i.is_deleted = 0
         ORDER BY i.date DESC
         LIMIT 100''',
    );
    final List<InvoiceModel> result = [];
    for (final row in rows) {
      final id = row['id'] as String;
      result.add(InvoiceModel.fromMap(row,
          items: await _getItems(id), payments: await _getPayments(id)));
    }
    return result;
  }

  Future<Map<String, dynamic>> getDailySummary(String date) async {
    final rows = await _db.rawQuery(
      '''SELECT SUM(amount) as total, method, COUNT(*) as count
         FROM payments
         WHERE date(paid_at) = ?
         GROUP BY method''',
      [date],
    );
    double total = 0;
    final byMethod = <String, double>{};
    for (final row in rows) {
      final amount = (row['total'] as num?)?.toDouble() ?? 0;
      total += amount;
      byMethod[row['method'] as String] = amount;
    }
    return {'total': total, 'by_method': byMethod};
  }

  Future<InvoiceModel> createInvoice({
    required String patientId,
    String? consultationId,
    required List<Map<String, dynamic>> items,
    double discount = 0,
    String? notes,
  }) async {
    final id = KeyGenerator.uuid();
    final invoiceNumber = await NumberGenerator.instance.nextInvoiceNumber();
    final now = DateTime.now().toIso8601String();
    final today = now.substring(0, 10);
    final config = ClinicConfig.instance;
    final currentUser = AuthService.instance.currentUser!;

    double subtotal = 0;
    for (final item in items) {
      final qty = (item['quantity'] as int?) ?? 1;
      final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
      subtotal += qty * price;
    }
    final total = subtotal - discount;

    final invoice = InvoiceModel(
      id: id,
      invoiceNumber: invoiceNumber,
      patientId: patientId,
      consultationId: consultationId,
      date: today,
      subtotal: subtotal,
      discount: discount,
      totalAmount: total,
      status: 'unpaid',
      notes: notes,
      createdBy: currentUser.id,
      createdAt: now,
      updatedAt: now,
      syncVersion: 1,
      deviceId: config.deviceId,
    );

    await _db.insert('invoices', invoice.toMap());

    final List<InvoiceItemModel> itemModels = [];
    for (final item in items) {
      final itemId = KeyGenerator.uuid();
      final qty = (item['quantity'] as int?) ?? 1;
      final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
      final itemModel = InvoiceItemModel(
        id: itemId,
        invoiceId: id,
        description: item['description'] as String,
        quantity: qty,
        unitPrice: price,
        total: qty * price,
      );
      await _db.insert('invoice_items', itemModel.toMap());
      itemModels.add(itemModel);
    }

    await SyncQueueManager.instance.enqueue(
      tableName: 'invoices',
      recordId: id,
      operation: 'INSERT',
      payload: invoice.toMap(),
      syncVersion: 1,
    );

    await AuditLogger.instance.log(
      action: 'CREATE',
      tableName: 'invoices',
      recordId: id,
      newValue: invoice.toMap(),
    );

    return InvoiceModel.fromMap(invoice.toMap(), items: itemModels);
  }

  Future<PaymentModel> recordPayment({
    required String invoiceId,
    required String patientId,
    required double amount,
    required String method,
    String? reference,
    String? notes,
  }) async {
    final id = KeyGenerator.uuid();
    final receiptNumber = await NumberGenerator.instance.nextReceiptNumber();
    final now = DateTime.now().toIso8601String();
    final config = ClinicConfig.instance;
    final currentUser = AuthService.instance.currentUser!;

    final payment = PaymentModel(
      id: id,
      receiptNumber: receiptNumber,
      invoiceId: invoiceId,
      patientId: patientId,
      amount: amount,
      method: method,
      reference: reference,
      paidAt: now,
      receivedBy: currentUser.id,
      notes: notes,
      syncVersion: 1,
      deviceId: config.deviceId,
    );

    await _db.insert('payments', payment.toMap());

    // Check if invoice is now fully paid
    final invoiceRows = await _db.query('invoices',
        where: 'id = ?', whereArgs: [invoiceId], limit: 1);
    if (invoiceRows.isNotEmpty) {
      final invoiceTotal = ((invoiceRows.first['total_amount'] ?? invoiceRows.first['total']) as num?)?.toDouble() ?? 0;
      final paidRows = await _db.rawQuery(
          'SELECT SUM(amount) as total FROM payments WHERE invoice_id = ?',
          [invoiceId]);
      final paid = (paidRows.first['total'] as num?)?.toDouble() ?? 0;
      final newStatus = paid >= invoiceTotal ? 'paid' : 'partial';
      await _db.update('invoices', {'status': newStatus, 'updated_at': now},
          where: 'id = ?', whereArgs: [invoiceId]);
    }

    await SyncQueueManager.instance.enqueue(
      tableName: 'payments',
      recordId: id,
      operation: 'INSERT',
      payload: payment.toMap(),
      syncVersion: 1,
    );

    await AuditLogger.instance.log(
      action: 'PAYMENT',
      tableName: 'payments',
      recordId: id,
      newValue: payment.toMap(),
    );

    return payment;
  }

  /// V2: Get a single invoice with items and payments
  Future<InvoiceModel?> getInvoice(String id) async {
    final rows = await _db.rawQuery(
      """SELECT i.*, p.full_name as patient_name, p.file_number as patient_file_number
         FROM invoices i
         LEFT JOIN patients p ON p.id = i.patient_id
         WHERE i.id = ? AND i.is_deleted = 0 LIMIT 1""",
      [id],
    );
    if (rows.isEmpty) return null;
    return InvoiceModel.fromMap(rows.first,
        items: await _getItems(id), payments: await _getPayments(id));
  }

  /// V2: List all invoices (for billing list screen)
  Future<List<InvoiceModel>> listInvoices({int limit = 200}) async {
    final rows = await _db.rawQuery(
      """SELECT i.*, p.full_name as patient_name, p.file_number as patient_file_number
         FROM invoices i
         LEFT JOIN patients p ON p.id = i.patient_id
         WHERE i.is_deleted = 0
         ORDER BY i.date DESC LIMIT ?""",
      [limit],
    );
    final result = <InvoiceModel>[];
    for (final row in rows) {
      final iid = row['id'] as String;
      result.add(InvoiceModel.fromMap(row,
          items: await _getItems(iid), payments: await _getPayments(iid)));
    }
    return result;
  }

  /// V2: Mark invoice as fully paid instantly
  Future<void> markPaid(String invoiceId) async {
    final now = DateTime.now().toIso8601String();
    await _db.update('invoices',
        {'status': 'paid', 'paid_at': now, 'updated_at': now},
        where: 'id = ?', whereArgs: [invoiceId]);
    await AuditLogger.instance.log(
      action: 'MARK_PAID',
      tableName: 'invoices',
      recordId: invoiceId,
      newValue: <String, dynamic>{'status': 'paid', 'paid_at': now},
    );
  }
}
