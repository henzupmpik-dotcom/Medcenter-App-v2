import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class KeyGenerator {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();

  /// Generates a CLINIC KEY in format XXXX-XXXX-XXXX-XXXX
  static String generateClinicKey() {
    String segment() =>
        List.generate(4, (_) => _chars[_random.nextInt(_chars.length)]).join();
    return '${segment()}-${segment()}-${segment()}-${segment()}';
  }

  /// Generates a CLINIC ID in format CL-YYYY-NNNNN
  static String generateClinicId() {
    final year = DateTime.now().year;
    final num = _random.nextInt(99999).toString().padLeft(5, '0');
    return 'CL-$year-$num';
  }

  /// Generates a DEVICE ID in format DEV-XXXXXX
  static String generateDeviceId() {
    final part =
        List.generate(6, (_) => _chars[_random.nextInt(_chars.length)]).join();
    return 'DEV-$part';
  }

  /// Generates a UUID v4
  static String uuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  /// SHA-256 hash of a value
  static String hash(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Simple PIN hash
  static String hashPin(String pin) => hash('MEDCENTER_PIN_$pin');
}
