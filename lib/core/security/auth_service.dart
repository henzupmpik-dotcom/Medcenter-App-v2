import 'package:flutter/foundation.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/shared/models/user_model.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  static const _sessionTimeoutMinutes = 30;
  DateTime? _lastActivity;

  bool get isSessionExpired {
    if (_lastActivity == null) return true;
    return DateTime.now().difference(_lastActivity!).inMinutes >= _sessionTimeoutMinutes;
  }

  void refreshSession() {
    _lastActivity = DateTime.now();
  }

  /// Attempt PIN login — returns user or null
  Future<UserModel?> login(String pin) async {
    final pinHash = KeyGenerator.hashPin(pin);
    final rows = await DatabaseHelper.instance.query(
      'users',
      where: 'pin_hash = ? AND is_active = 1',
      whereArgs: [pinHash],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    _currentUser = UserModel.fromMap(rows.first);
    _lastActivity = DateTime.now();
    notifyListeners();
    return _currentUser;
  }

  void logout() {
    _currentUser = null;
    _lastActivity = null;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    return RolePermissions.can(_currentUser!.role, permission);
  }

  /// Create the initial admin user (first-time setup)
  Future<void> createAdminUser({
    required String name,
    required String pin,
    required String deviceId,
  }) async {
    final id = KeyGenerator.uuid();
    final now = DateTime.now().toIso8601String();
    await DatabaseHelper.instance.insert('users', {
      'id': id,
      'name': name,
      'role': 'admin',
      'pin_hash': KeyGenerator.hashPin(pin),
      'device_id': deviceId,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<UserModel>> getAllUsers() async {
    final rows = await DatabaseHelper.instance.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return rows.map(UserModel.fromMap).toList();
  }
}

class RolePermissions {
  static const Map<String, List<String>> _matrix = {
    'admin': [
      'patient.view', 'patient.create', 'patient.edit',
      'consultation.view', 'consultation.create',
      'vitals.create',
      'prescription.view', 'prescription.create',
      'invoice.create', 'invoice.view',
      'payment.create', 'payment.view',
      'appointment.view', 'appointment.create',
      'lab.request', 'lab.upload',
      'staff.manage',
      'settings.manage',
      'reports.view',
      'records.delete',
    ],
    'doctor': [
      'patient.view',
      'consultation.view', 'consultation.create',
      'vitals.create',
      'prescription.view', 'prescription.create',
      'invoice.view',
      'appointment.view',
      'lab.request', 'lab.upload',
      'reports.view',
    ],
    'nurse': [
      'patient.view',
      'consultation.view',
      'vitals.create',
      'prescription.view',
      'lab.request', 'lab.upload',
    ],
    'reception': [
      'patient.view', 'patient.create', 'patient.edit',
      'prescription.view',
      'invoice.create', 'invoice.view',
      'payment.create', 'payment.view',
      'appointment.view', 'appointment.create',
      'reports.view',
    ],
  };

  static bool can(String role, String permission) {
    return _matrix[role]?.contains(permission) ?? false;
  }
}
