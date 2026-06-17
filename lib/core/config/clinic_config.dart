import 'package:medcenter/core/database/database_helper.dart';

class ClinicConfig {
  ClinicConfig._();
  static final ClinicConfig instance = ClinicConfig._();

  final Map<String, String> _cache = {};

  bool get isConfigured => _cache.containsKey('clinic_id') && _cache['clinic_id'] != null;

  String get clinicId => _cache['clinic_id'] ?? '';
  String get clinicKey => _cache['clinic_key'] ?? '';
  String get clinicName => _cache['clinic_name'] ?? 'MedCenter';
  String get clinicAddress => _cache['clinic_address'] ?? '';
  String get clinicPhone => _cache['clinic_phone'] ?? '';
  String get clinicEmail => _cache['clinic_email'] ?? '';
  String get country => _cache['country'] ?? 'ZA';
  String get currency => _cache['currency'] ?? 'ZAR';
  String get currencySymbol => currency == 'USD' ? 'USD' : 'R';
  String get deviceId => _cache['device_id'] ?? '';
  String get deviceName => _cache['device_name'] ?? 'Device';
  int get apiPort => int.tryParse(_cache['api_port'] ?? '8080') ?? 8080;

  Future<void> load() async {
    final rows = await DatabaseHelper.instance.query('clinic_config');
    _cache.clear();
    for (final row in rows) {
      _cache[row['key'] as String] = row['value'] as String;
    }
  }

  Future<void> set(String key, String value) async {
    _cache[key] = value;
    await DatabaseHelper.instance.insert(
      'clinic_config',
      {'key': key, 'value': value},
    );
  }

  Future<void> setAll(Map<String, String> map) async {
    for (final entry in map.entries) {
      await set(entry.key, entry.value);
    }
  }

  String? get(String key) => _cache[key];
}
