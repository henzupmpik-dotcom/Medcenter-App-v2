class AppointmentModel {
  final String id;
  final String appointmentNumber;
  final String patientId;
  final String doctorId;
  final String scheduledAt;
  final int durationMinutes;
  final String status;
  final String? reason;
  final String? notes;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;
  final int syncVersion;
  final String? deviceId;

  // Joined fields
  final String? patientName;
  final String? patientFileNumber;
  final String? patientPhone;
  final String? doctorName;

  const AppointmentModel({
    required this.id,
    required this.appointmentNumber,
    required this.patientId,
    required this.doctorId,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.status = 'booked',
    this.reason,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.syncVersion = 1,
    this.deviceId,
    this.patientName,
    this.patientFileNumber,
    this.patientPhone,
    this.doctorName,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) => AppointmentModel(
        id: map['id'] as String,
        appointmentNumber: map['appointment_number'] as String,
        patientId: map['patient_id'] as String,
        doctorId: map['doctor_id'] as String,
        scheduledAt: map['scheduled_at'] as String,
        durationMinutes: map['duration_minutes'] as int? ?? 30,
        status: map['status'] as String? ?? 'booked',
        reason: map['reason'] as String?,
        notes: map['notes'] as String?,
        createdBy: map['created_by'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        syncVersion: map['sync_version'] as int? ?? 1,
        deviceId: map['device_id'] as String?,
        patientName: map['patient_name'] as String?,
        patientFileNumber: map['patient_file_number'] as String?,
        patientPhone: map['patient_phone'] as String?,
        doctorName: map['doctor_name'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'appointment_number': appointmentNumber,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'scheduled_at': scheduledAt,
        'duration_minutes': durationMinutes,
        'status': status,
        'reason': reason,
        'notes': notes,
        'created_by': createdBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_version': syncVersion,
        'device_id': deviceId,
        'is_deleted': 0,
      };

  AppointmentModel copyWith({String? status, String? notes, String? scheduledAt}) =>
      AppointmentModel(
        id: id,
        appointmentNumber: appointmentNumber,
        patientId: patientId,
        doctorId: doctorId,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        durationMinutes: durationMinutes,
        status: status ?? this.status,
        reason: reason,
        notes: notes ?? this.notes,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        syncVersion: syncVersion + 1,
        deviceId: deviceId,
        patientName: patientName,
        patientFileNumber: patientFileNumber,
        patientPhone: patientPhone,
        doctorName: doctorName,
      );

  DateTime get scheduledDateTime => DateTime.parse(scheduledAt);

  String get statusLabel {
    switch (status) {
      case 'booked': return 'Booked';
      case 'arrived': return 'Arrived';
      case 'in-progress': return 'In Progress';
      case 'done': return 'Done';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}
