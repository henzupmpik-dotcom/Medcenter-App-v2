class PrescriptionModel {
  final String id;
  final String prescriptionNumber;
  final String? consultationId;
  final String patientId;
  final String doctorId;
  final String date;
  final String? notes;
  final String status;
  final bool isRepeat;
  final String createdAt;
  final String updatedAt;
  final int syncVersion;
  final String? deviceId;
  final String? eventId;

  // Joined fields
  final String? patientName;
  final String? patientFileNumber;
  final String? doctorName;
  final List<PrescriptionItemModel> items;

  const PrescriptionModel({
    required this.id,
    required this.prescriptionNumber,
    this.consultationId,
    required this.patientId,
    required this.doctorId,
    required this.date,
    this.notes,
    this.status = 'active',
    this.isRepeat = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncVersion = 1,
    this.deviceId,
    this.eventId,
    this.patientName,
    this.patientFileNumber,
    this.doctorName,
    this.items = const [],
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> map,
      {List<PrescriptionItemModel> items = const []}) =>
      PrescriptionModel(
        id: map['id'] as String,
        prescriptionNumber: map['prescription_number'] as String,
        consultationId: map['consultation_id'] as String?,
        patientId: map['patient_id'] as String,
        doctorId: map['doctor_id'] as String,
        date: map['date'] as String,
        notes: map['notes'] as String?,
        status: map['status'] as String? ?? 'active',
        isRepeat: (map['is_repeat'] as int?) == 1,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        syncVersion: map['sync_version'] as int? ?? 1,
        deviceId: map['device_id'] as String?,
        eventId: map['event_id'] as String?,
        patientName: map['patient_name'] as String?,
        patientFileNumber: map['patient_file_number'] as String?,
        doctorName: map['doctor_name'] as String?,
        items: items,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'prescription_number': prescriptionNumber,
        'consultation_id': consultationId,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'date': date,
        'notes': notes,
        'status': status,
        'is_repeat': isRepeat ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_version': syncVersion,
        'device_id': deviceId,
        'event_id': eventId,
        'is_deleted': 0,
      };
}

class PrescriptionItemModel {
  final String id;
  final String prescriptionId;
  final String medicationName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? route;      // V2: oral | iv | im | topical | inhaled
  final int refills;        // V2: number of authorised refills
  final String? instructions;
  final int? quantity;

  const PrescriptionItemModel({
    required this.id,
    required this.prescriptionId,
    required this.medicationName,
    this.dosage,
    this.frequency,
    this.duration,
    this.route,
    this.refills = 0,
    this.instructions,
    this.quantity,
  });

  factory PrescriptionItemModel.fromMap(Map<String, dynamic> map) =>
      PrescriptionItemModel(
        id: map['id'] as String,
        prescriptionId: map['prescription_id'] as String,
        medicationName: map['medication_name'] as String,
        dosage: map['dosage'] as String?,
        frequency: map['frequency'] as String?,
        duration: map['duration'] as String?,
        route: map['route'] as String?,
        refills: map['refills'] as int? ?? 0,
        instructions: map['instructions'] as String?,
        quantity: map['quantity'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'prescription_id': prescriptionId,
        'medication_name': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'route': route,
        'refills': refills,
        'instructions': instructions,
        'quantity': quantity,
      };

  String get frequencyLabel {
    switch (frequency) {
      case 'once_daily': return 'Once daily';
      case 'twice_daily': return 'Twice daily';
      case 'three_daily': return 'Three times daily';
      case 'as_needed': return 'As needed';
      default: return frequency ?? '';
    }
  }

  String get routeLabel {
    switch (route) {
      case 'oral': return 'Oral';
      case 'iv': return 'IV';
      case 'im': return 'IM';
      case 'topical': return 'Topical';
      case 'inhaled': return 'Inhaled';
      default: return route ?? '';
    }
  }
}
