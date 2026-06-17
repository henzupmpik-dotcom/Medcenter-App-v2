class ConsultationModel {
  final String id;
  final String patientId;
  final String userId;
  final String date;
  final String? chiefComplaint;
  final String? history;
  final String? examination;
  final String? diagnosis;
  final String? icd10Code;
  final String? treatmentPlan;
  final String? followUpDate;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final int syncVersion;
  final String? deviceId;

  // Joined fields
  final String? patientName;
  final String? patientFileNumber;
  final String? doctorName;

  const ConsultationModel({
    required this.id,
    required this.patientId,
    required this.userId,
    required this.date,
    this.chiefComplaint,
    this.history,
    this.examination,
    this.diagnosis,
    this.icd10Code,
    this.treatmentPlan,
    this.followUpDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncVersion = 1,
    this.deviceId,
    this.patientName,
    this.patientFileNumber,
    this.doctorName,
  });

  factory ConsultationModel.fromMap(Map<String, dynamic> map) => ConsultationModel(
        id: map['id'] as String,
        patientId: map['patient_id'] as String,
        userId: map['user_id'] as String,
        date: map['date'] as String,
        chiefComplaint: map['chief_complaint'] as String?,
        history: map['history'] as String?,
        examination: map['examination'] as String?,
        diagnosis: map['diagnosis'] as String?,
        icd10Code: map['icd10_code'] as String?,
        treatmentPlan: map['treatment_plan'] as String?,
        followUpDate: map['follow_up_date'] as String?,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        syncVersion: map['sync_version'] as int? ?? 1,
        deviceId: map['device_id'] as String?,
        patientName: map['patient_name'] as String?,
        patientFileNumber: map['patient_file_number'] as String?,
        doctorName: map['doctor_name'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'patient_id': patientId,
        'user_id': userId,
        'date': date,
        'chief_complaint': chiefComplaint,
        'history': history,
        'examination': examination,
        'diagnosis': diagnosis,
        'icd10_code': icd10Code,
        'treatment_plan': treatmentPlan,
        'follow_up_date': followUpDate,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_version': syncVersion,
        'device_id': deviceId,
        'is_deleted': 0,
      };
}

class VitalsModel {
  final String id;
  final String consultationId;
  final String patientId;
  final int? bloodPressureSys;
  final int? bloodPressureDia;
  final double? temperature;
  final double? weightKg;
  final double? heightCm;
  final int? pulseRate;
  final int? oxygenSaturation;
  final int? respiratoryRate;
  final String recordedAt;
  final String? recordedBy;

  const VitalsModel({
    required this.id,
    required this.consultationId,
    required this.patientId,
    this.bloodPressureSys,
    this.bloodPressureDia,
    this.temperature,
    this.weightKg,
    this.heightCm,
    this.pulseRate,
    this.oxygenSaturation,
    this.respiratoryRate,
    required this.recordedAt,
    this.recordedBy,
  });

  factory VitalsModel.fromMap(Map<String, dynamic> map) => VitalsModel(
        id: map['id'] as String,
        consultationId: map['consultation_id'] as String,
        patientId: map['patient_id'] as String,
        bloodPressureSys: map['blood_pressure_sys'] as int?,
        bloodPressureDia: map['blood_pressure_dia'] as int?,
        temperature: (map['temperature'] as num?)?.toDouble(),
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        heightCm: (map['height_cm'] as num?)?.toDouble(),
        pulseRate: map['pulse_rate'] as int?,
        oxygenSaturation: map['oxygen_saturation'] as int?,
        respiratoryRate: map['respiratory_rate'] as int?,
        recordedAt: map['recorded_at'] as String,
        recordedBy: map['recorded_by'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'consultation_id': consultationId,
        'patient_id': patientId,
        'blood_pressure_sys': bloodPressureSys,
        'blood_pressure_dia': bloodPressureDia,
        'temperature': temperature,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'pulse_rate': pulseRate,
        'oxygen_saturation': oxygenSaturation,
        'respiratory_rate': respiratoryRate,
        'recorded_at': recordedAt,
        'recorded_by': recordedBy,
        'sync_version': 1,
      };

  String? get bmi {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final h = heightCm! / 100;
    final bmi = weightKg! / (h * h);
    return bmi.toStringAsFixed(1);
  }
}
