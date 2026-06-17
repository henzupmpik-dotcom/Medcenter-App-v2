class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String patientId;
  final String? consultationId;
  final String date;
  final String? dueDate;
  final double subtotal;
  final double taxAmount;
  final double discount;
  final double totalAmount;
  final String status;
  final String? paymentMethod;
  final String? medicalAidName;
  final String? medicalAidMemberNo;
  final String? medicalAidAuthCode;
  final String? notes;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;
  final String? paidAt;
  final int syncVersion;
  final String? deviceId;

  // Joined
  final String? patientName;
  final String? patientFileNumber;
  final List<InvoiceItemModel> items;
  final List<PaymentModel> payments;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.patientId,
    this.consultationId,
    required this.date,
    this.dueDate,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discount = 0,
    this.totalAmount = 0,
    this.status = 'unpaid',
    this.paymentMethod,
    this.medicalAidName,
    this.medicalAidMemberNo,
    this.medicalAidAuthCode,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.syncVersion = 1,
    this.deviceId,
    this.patientName,
    this.patientFileNumber,
    this.items = const [],
    this.payments = const [],
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map,
      {List<InvoiceItemModel> items = const [],
      List<PaymentModel> payments = const []}) =>
      InvoiceModel(
        id: map['id'] as String,
        invoiceNumber: map['invoice_number'] as String,
        patientId: map['patient_id'] as String,
        consultationId: map['consultation_id'] as String?,
        date: map['date'] as String,
        dueDate: map['due_date'] as String?,
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        // Support both old 'total' column and new 'total_amount'
        totalAmount: (map['total_amount'] as num?)?.toDouble() ??
            (map['total'] as num?)?.toDouble() ?? 0,
        status: map['status'] as String? ?? 'unpaid',
        paymentMethod: map['payment_method'] as String?,
        medicalAidName: map['medical_aid_name'] as String?,
        medicalAidMemberNo: map['medical_aid_member_no'] as String?,
        medicalAidAuthCode: map['medical_aid_auth_code'] as String?,
        notes: map['notes'] as String?,
        createdBy: map['created_by'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        paidAt: map['paid_at'] as String?,
        syncVersion: map['sync_version'] as int? ?? 1,
        deviceId: map['device_id'] as String?,
        patientName: map['patient_name'] as String?,
        patientFileNumber: map['patient_file_number'] as String?,
        items: items,
        payments: payments,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'patient_id': patientId,
        'consultation_id': consultationId,
        'date': date,
        'due_date': dueDate,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'discount': discount,
        'total_amount': totalAmount,
        'status': status,
        'payment_method': paymentMethod,
        'medical_aid_name': medicalAidName,
        'medical_aid_member_no': medicalAidMemberNo,
        'medical_aid_auth_code': medicalAidAuthCode,
        'notes': notes,
        'created_by': createdBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'paid_at': paidAt,
        'sync_version': syncVersion,
        'device_id': deviceId,
        'is_deleted': 0,
      };

  double get amountPaid => payments.fold(0, (sum, p) => sum + p.amount);
  double get balance => totalAmount - amountPaid;

  InvoiceModel copyWith({
    String? status,
    String? paymentMethod,
    String? paidAt,
    List<PaymentModel>? payments,
  }) =>
      InvoiceModel(
        id: id, invoiceNumber: invoiceNumber, patientId: patientId,
        consultationId: consultationId, date: date, dueDate: dueDate,
        subtotal: subtotal, taxAmount: taxAmount, discount: discount,
        totalAmount: totalAmount,
        status: status ?? this.status,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        medicalAidName: medicalAidName, medicalAidMemberNo: medicalAidMemberNo,
        medicalAidAuthCode: medicalAidAuthCode, notes: notes, createdBy: createdBy,
        createdAt: createdAt, updatedAt: updatedAt,
        paidAt: paidAt ?? this.paidAt,
        syncVersion: syncVersion, deviceId: deviceId,
        patientName: patientName, patientFileNumber: patientFileNumber,
        items: items, payments: payments ?? this.payments,
      );
}

class InvoiceItemModel {
  final String id;
  final String invoiceId;
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  const InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.total = 0,
  });

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) => InvoiceItemModel(
        id: map['id'] as String,
        invoiceId: map['invoice_id'] as String,
        description: map['description'] as String,
        quantity: map['quantity'] as int? ?? 1,
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total': total,
      };
}

class PaymentModel {
  final String id;
  final String receiptNumber;
  final String invoiceId;
  final String patientId;
  final double amount;
  final String method;
  final String? reference;
  final String paidAt;
  final String? receivedBy;
  final String? notes;
  final int syncVersion;
  final String? deviceId;

  const PaymentModel({
    required this.id,
    required this.receiptNumber,
    required this.invoiceId,
    required this.patientId,
    required this.amount,
    required this.method,
    this.reference,
    required this.paidAt,
    this.receivedBy,
    this.notes,
    this.syncVersion = 1,
    this.deviceId,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) => PaymentModel(
        id: map['id'] as String,
        receiptNumber: map['receipt_number'] as String,
        invoiceId: map['invoice_id'] as String,
        patientId: map['patient_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        method: map['method'] as String,
        reference: map['reference'] as String?,
        paidAt: map['paid_at'] as String,
        receivedBy: map['received_by'] as String?,
        notes: map['notes'] as String?,
        syncVersion: map['sync_version'] as int? ?? 1,
        deviceId: map['device_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'receipt_number': receiptNumber,
        'invoice_id': invoiceId,
        'patient_id': patientId,
        'amount': amount,
        'method': method,
        'reference': reference,
        'paid_at': paidAt,
        'received_by': receivedBy,
        'notes': notes,
        'sync_version': syncVersion,
        'device_id': deviceId,
      };
}
