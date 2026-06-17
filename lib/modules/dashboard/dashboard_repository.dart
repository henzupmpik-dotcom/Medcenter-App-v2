import 'package:medcenter/core/database/database_helper.dart';

class DashboardStats {
  final int totalAppointmentsToday;
  final int completedConsultationsToday;
  final int pendingAppointmentsToday;
  final int newPatientsToday;
  final double totalRevenueToday;
  final int outstandingInvoices;
  final int prescriptionsIssuedToday;
  final int staffOnDuty;
  final List<Map<String, dynamic>> todayTimeline;
  final List<Map<String, dynamic>> last7DaysRevenue;

  const DashboardStats({
    this.totalAppointmentsToday = 0,
    this.completedConsultationsToday = 0,
    this.pendingAppointmentsToday = 0,
    this.newPatientsToday = 0,
    this.totalRevenueToday = 0,
    this.outstandingInvoices = 0,
    this.prescriptionsIssuedToday = 0,
    this.staffOnDuty = 0,
    this.todayTimeline = const [],
    this.last7DaysRevenue = const [],
  });
}

class DashboardRepository {
  DashboardRepository._();
  static final DashboardRepository instance = DashboardRepository._();

  final _db = DatabaseHelper.instance;

  Future<DashboardStats> loadToday() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 6))
        .toIso8601String()
        .substring(0, 10);

    final apptTotal = await _db.rawQuery(
      "SELECT COUNT(*) as c FROM appointments WHERE date(scheduled_at) = ? AND is_deleted = 0",
      [today],
    );
    final consults = await _db.rawQuery(
      "SELECT COUNT(*) as c FROM consultations WHERE date = ? AND is_deleted = 0",
      [today],
    );
    final pending = await _db.rawQuery(
      "SELECT COUNT(*) as c FROM appointments WHERE date(scheduled_at) = ? AND status IN ('booked','arrived') AND is_deleted = 0",
      [today],
    );
    final newPatients = await _db.rawQuery(
      "SELECT COUNT(*) as c FROM patients WHERE date(created_at) = ? AND is_deleted = 0",
      [today],
    );
    final revenue = await _db.rawQuery(
      "SELECT COALESCE(SUM(total_amount), 0) as s FROM invoices WHERE date = ? AND status = 'paid' AND is_deleted = 0",
      [today],
    );
    final outstanding = await _db.rawQuery(
      "SELECT COUNT(*) as c FROM invoices WHERE status IN ('unpaid','partial','overdue') AND is_deleted = 0",
    );
    final rxToday = await _db.rawQuery(
      "SELECT COUNT(*) as c FROM prescriptions WHERE date = ? AND is_deleted = 0",
      [today],
    );
    final staff = await _db.rawQuery(
      "SELECT COUNT(*) as c FROM users WHERE is_active = 1",
    );
    final timeline = await _db.rawQuery(
      '''SELECT a.id, a.scheduled_at, a.status, a.duration_minutes,
                u.name as doctor_name, a.reason,
                substr(p.full_name, 1, 1) as patient_initial
         FROM appointments a
         LEFT JOIN patients p ON p.id = a.patient_id
         LEFT JOIN users u ON u.id = a.doctor_id
         WHERE date(a.scheduled_at) = ? AND a.is_deleted = 0
         ORDER BY a.scheduled_at ASC LIMIT 50''',
      [today],
    );
    final revenueChart = await _db.rawQuery(
      '''SELECT date as day, COALESCE(SUM(total_amount), 0) as revenue
         FROM invoices
         WHERE date >= ? AND status = 'paid' AND is_deleted = 0
         GROUP BY date ORDER BY date ASC''',
      [sevenDaysAgo],
    );

    return DashboardStats(
      totalAppointmentsToday: (apptTotal.first['c'] as int?) ?? 0,
      completedConsultationsToday: (consults.first['c'] as int?) ?? 0,
      pendingAppointmentsToday: (pending.first['c'] as int?) ?? 0,
      newPatientsToday: (newPatients.first['c'] as int?) ?? 0,
      totalRevenueToday: (revenue.first['s'] as num?)?.toDouble() ?? 0,
      outstandingInvoices: (outstanding.first['c'] as int?) ?? 0,
      prescriptionsIssuedToday: (rxToday.first['c'] as int?) ?? 0,
      staffOnDuty: (staff.first['c'] as int?) ?? 0,
      todayTimeline: List<Map<String, dynamic>>.from(timeline),
      last7DaysRevenue: List<Map<String, dynamic>>.from(revenueChart),
    );
  }
}
