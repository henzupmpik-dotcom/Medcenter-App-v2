class PatientModel {
  final String id;
  final String fileNumber;
  final String fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? nationalId;
  final String? address;
  final String? phone;
  final String? email;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinRelation;
  final String? photoPath;
  final String? bloodGroup;
  final bool isArchived;
  final String? createdBy;
  final String createdAt;
  final String updatedAt;
  final int syncVersion;
  final String? deviceId;

  const PatientModel({
    required this.id,
    required this.fileNumber,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.nationalId,
    this.address,
    this.phone,
    this.email,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinRelation,
    this.photoPath,
    this.bloodGroup,
    this.isArchived = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.syncVersion = 1,
    this.deviceId,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) => PatientModel(
        id: map['id'] as String,
        fileNumber: map['file_number'] as String,
        fullName: map['full_name'] as String,
        dateOfBirth: map['date_of_birth'] as String?,
        gender: map['gender'] as String?,
        nationalId: map['national_id'] as String?,
        address: map['address'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        nextOfKinName: map['next_of_kin_name'] as String?,
        nextOfKinPhone: map['next_of_kin_phone'] as String?,
        nextOfKinRelation: map['next_of_kin_relation'] as String?,
        photoPath: map['photo_path'] as String?,
        bloodGroup: map['blood_group'] as String?,
        isArchived: (map['is_archived'] as int?) == 1,
        createdBy: map['created_by'] as String?,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        syncVersion: map['sync_version'] as int? ?? 1,
        deviceId: map['device_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'file_number': fileNumber,
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'national_id': nationalId,
        'address': address,
        'phone': phone,
        'email': email,
        'next_of_kin_name': nextOfKinName,
        'next_of_kin_phone': nextOfKinPhone,
        'next_of_kin_relation': nextOfKinRelation,
        'photo_path': photoPath,
        'blood_group': bloodGroup,
        'is_archived': isArchived ? 1 : 0,
        'created_by': createdBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_version': syncVersion,
        'device_id': deviceId,
        'is_deleted': 0,
      };

  PatientModel copyWith({
    String? fullName,
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
    bool? isArchived,
    String? updatedAt,
    int? syncVersion,
  }) =>
      PatientModel(
        id: id,
        fileNumber: fileNumber,
        fullName: fullName ?? this.fullName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        nationalId: nationalId ?? this.nationalId,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        nextOfKinName: nextOfKinName ?? this.nextOfKinName,
        nextOfKinPhone: nextOfKinPhone ?? this.nextOfKinPhone,
        nextOfKinRelation: nextOfKinRelation ?? this.nextOfKinRelation,
        photoPath: photoPath ?? this.photoPath,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        isArchived: isArchived ?? this.isArchived,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncVersion: syncVersion ?? this.syncVersion,
        deviceId: deviceId,
      );

  int? get age {
    if (dateOfBirth == null) return null;
    final dob = DateTime.tryParse(dateOfBirth!);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
