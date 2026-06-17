import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy • HH:mm');
  static final _timeFormat = DateFormat('HH:mm');

  /// Format ISO date string: "2026-06-15" → "15 Jun 2026"
  static String format(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return _dateFormat.format(date);
    } catch (_) {
      return isoDate;
    }
  }

  /// Format ISO datetime string: "2026-06-15T10:30:00" → "15 Jun 2026 • 10:30"
  static String formatDateTime(String isoDateTime) {
    try {
      final date = DateTime.parse(isoDateTime);
      return _dateTimeFormat.format(date);
    } catch (_) {
      return isoDateTime;
    }
  }

  /// Format DateTime object: "15 Jun 2026"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Format as short date: "15/06/2026"
  static String formatShort(String isoDate) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  /// Format time only: "10:30"
  static String formatTime(String isoDateTime) {
    try {
      final date = DateTime.parse(isoDateTime);
      return _timeFormat.format(date);
    } catch (_) {
      return isoDateTime;
    }
  }

  /// Today's ISO date string: "2026-06-15"
  static String today() =>
      DateTime.now().toIso8601String().substring(0, 10);

  /// Relative label: "Today", "Yesterday", or formatted date
  static String relative(String isoDate) {
    try {
      final date = DateTime.parse(isoDate.substring(0, 10));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final d = DateTime(date.year, date.month, date.day);
      final diff = today.difference(d).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) return '$diff days ago';
      return _dateFormat.format(date);
    } catch (_) {
      return isoDate;
    }
  }
}
