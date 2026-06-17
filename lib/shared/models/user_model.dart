class UserModel {
  final String id;
  final String name;
  final String role;
  final String pinHash;
  final String? deviceId;
  final bool isActive;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.pinHash,
    this.deviceId,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        role: map['role'] as String,
        pinHash: map['pin_hash'] as String,
        deviceId: map['device_id'] as String?,
        isActive: (map['is_active'] as int?) == 1,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'pin_hash': pinHash,
        'device_id': deviceId,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  String get roleLabel {
    switch (role) {
      case 'admin': return 'Administrator';
      case 'doctor': return 'Doctor';
      case 'nurse': return 'Nurse';
      case 'reception': return 'Receptionist';
      default: return role;
    }
  }
}
