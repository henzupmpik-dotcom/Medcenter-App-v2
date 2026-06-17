import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/modules/dashboard/dashboard_repository.dart';
import 'package:medcenter/shared/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await DashboardRepository.instance.loadToday();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicName = ClinicConfig.instance.clinicName ?? 'MedCenter';
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(clinicName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(today, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _DashboardBody(stats: _stats!),
                ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardStats stats;
  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Metric Cards Grid ---
        _SectionLabel(label: "Today's Summary"),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(
              label: 'Appointments',
              value: '${stats.totalAppointmentsToday}',
              icon: Icons.calendar_today,
              color: AppTheme.darkBlue,
              onTap: () => context.go('/appointments'),
            ),
            _MetricCard(
              label: 'Consultations',
              value: '${stats.completedConsultationsToday}',
              icon: Icons.medical_information_outlined,
              color: const Color(0xFF2E7D32),
              onTap: () => context.go('/patients'),
            ),
            _MetricCard(
              label: 'Pending',
              value: '${stats.pendingAppointmentsToday}',
              icon: Icons.hourglass_empty,
              color: const Color(0xFFE65100),
              onTap: () => context.go('/appointments'),
            ),
            _MetricCard(
              label: 'New Patients',
              value: '${stats.newPatientsToday}',
              icon: Icons.person_add_outlined,
              color: const Color(0xFF6A1B9A),
              onTap: () => context.go('/patients'),
            ),
            _MetricCard(
              label: "Revenue Today",
              value: 'R ${stats.totalRevenueToday.toStringAsFixed(0)}',
              icon: Icons.payments_outlined,
              color: const Color(0xFF00695C),
              onTap: () => context.go('/billing/list'),
            ),
            _MetricCard(
              label: 'Outstanding',
              value: '${stats.outstandingInvoices}',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFFC62828),
              onTap: () => context.go('/billing/list'),
            ),
            _MetricCard(
              label: 'Prescriptions',
              value: '${stats.prescriptionsIssuedToday}',
              icon: Icons.medication_outlined,
              color: const Color(0xFF1565C0),
              onTap: () => context.go('/patients'),
            ),
            _MetricCard(
              label: 'Staff Active',
              value: '${stats.staffOnDuty}',
              icon: Icons.badge_outlined,
              color: const Color(0xFF37474F),
              onTap: () => context.go('/staff'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Quick Actions ---
        _SectionLabel(label: 'Quick Actions'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: _QuickAction(
              label: '+ Appointment',
              icon: Icons.calendar_month,
              onTap: () => context.go('/appointments/new'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              label: '+ Patient',
              icon: Icons.person_add,
              onTap: () => context.go('/patients/new'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              label: 'Unpaid',
              icon: Icons.receipt_long,
              onTap: () => context.go('/billing/list'),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // --- Revenue Chart ---
        _SectionLabel(label: 'Revenue — Last 7 Days'),
        const SizedBox(height: 8),
        _RevenueChart(data: stats.last7DaysRevenue),
        const SizedBox(height: 20),

        // --- Today's Timeline ---
        if (stats.todayTimeline.isNotEmpty) ...[
          _SectionLabel(label: "Today's Appointments"),
          const SizedBox(height: 8),
          _AppointmentTimeline(timeline: stats.todayTimeline),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Color(0xFF546E7A),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey.shade400),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                  Text(label,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.darkBlue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.darkBlue, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBlue),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No revenue data yet',
              style: TextStyle(color: Color(0xFF90A4AE), fontSize: 13)),
        ),
      );
    }

    // Fill missing days with 0
    final Map<String, double> byDay = {};
    for (var i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      byDay[d] = 0;
    }
    for (final row in data) {
      byDay[row['day'] as String] = (row['revenue'] as num).toDouble();
    }

    final entries = byDay.entries.toList();
    final maxY = entries.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = maxY == 0 ? 100.0 : maxY * 1.3;

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = entries[groupIndex].key;
                final label = DateFormat('d MMM').format(DateTime.parse(day));
                return BarTooltipItem(
                  '$label\nR ${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                  final d = DateTime.parse(entries[idx].key);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('d/M').format(d),
                        style: const TextStyle(fontSize: 9, color: Color(0xFF90A4AE))),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((e) {
            final isToday = e.value.key == DateTime.now().toIso8601String().substring(0, 10);
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: isToday ? AppTheme.darkBlue : AppTheme.darkBlue.withValues(alpha: 0.35),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AppointmentTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> timeline;
  const _AppointmentTimeline({required this.timeline});

  Color _statusColor(String? status) {
    switch (status) {
      case 'arrived': return const Color(0xFF1565C0);
      case 'in_progress': return const Color(0xFFE65100);
      case 'completed': return const Color(0xFF2E7D32);
      case 'no_show': return const Color(0xFF757575);
      default: return const Color(0xFF546E7A);
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'booked': return 'Waiting';
      case 'arrived': return 'Arrived';
      case 'in_progress': return 'In Progress';
      case 'completed': return 'Done';
      case 'no_show': return 'No Show';
      default: return status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: timeline.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final appt = timeline[i];
          final dt = DateTime.tryParse(appt['scheduled_at'] as String? ?? '');
          final time = dt != null ? DateFormat('HH:mm').format(dt) : '--:--';
          final initial = (appt['patient_initial'] as String?) ?? '?';
          final status = appt['status'] as String?;
          final color = _statusColor(status);

          return Container(
            width: 110,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(initial,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ),
                    const SizedBox(width: 6),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}
