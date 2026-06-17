import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/modules/appointments/appointment_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/appointment_model.dart';
import 'package:medcenter/shared/models/user_model.dart';
import 'package:medcenter/shared/utils/date_formatter.dart';
import 'package:medcenter/shared/widgets/loading_overlay.dart';
import 'package:medcenter/modules/patients/patient_repository.dart';
import 'package:medcenter/shared/models/patient_model.dart';
import 'package:medcenter/core/security/auth_service.dart';

// ── Appointment List ──────────────────────────────────────────────────────────
class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  DateTime _selectedDate = DateTime.now();
  List<AppointmentModel> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await AppointmentRepository.instance.getForDate(_selectedDate);
    setState(() { _appointments = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/appointments/new');
              _load();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: AppTheme.primaryBlue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                  _load();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormatter.formatDate(_selectedDate),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ]),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? EmptyState(
                  icon: Icons.calendar_today,
                  message: 'No appointments for ${DateFormatter.formatDate(_selectedDate)}',
                  action: ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/appointments/new');
                      _load();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Book Appointment'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _appointments.length,
                    itemBuilder: (_, i) => _AppointmentTile(
                      appointment: _appointments[i],
                      onStatusChange: _load,
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/appointments/new');
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Book'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onStatusChange;
  const _AppointmentTile({required this.appointment, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final apt = appointment;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              apt.scheduledDateTime.hour.toString().padLeft(2, '0'),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            Text(
              ':${apt.scheduledDateTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        title: Text(apt.patientName ?? 'Patient',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (apt.reason != null) Text(apt.reason!, style: const TextStyle(fontSize: 12)),
            if (apt.doctorName != null)
              Text('Dr. ${apt.doctorName}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          child: _StatusBadge(apt.status),
          onSelected: (status) async {
            await AppointmentRepository.instance.updateStatus(apt.id, status);
            onStatusChange();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'booked', child: Text('Booked')),
            PopupMenuItem(value: 'arrived', child: Text('Arrived')),
            PopupMenuItem(value: 'in-progress', child: Text('In Progress')),
            PopupMenuItem(value: 'done', child: Text('Done')),
            PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.statusColor(status).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status.replaceAll('-', ' ').toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.statusColor(status)),
        ),
      );
}

// ── Appointment Form ──────────────────────────────────────────────────────────
class AppointmentFormScreen extends StatefulWidget {
  final String? patientId;
  const AppointmentFormScreen({super.key, this.patientId});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  int _duration = 30;
  PatientModel? _patient;
  UserModel? _doctor;
  List<PatientModel> _patients = [];
  List<UserModel> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final patients = await PatientRepository.instance.getAll();
    final users = await AuthService.instance.getAllUsers();
    setState(() {
      _patients = patients;
      _doctors = users.where((u) => u.role == 'doctor' || u.role == 'admin').toList();
      if (widget.patientId != null) {
        _patient = patients.where((p) => p.id == widget.patientId).firstOrNull;
      }
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_patient == null || _doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select patient and doctor')));
      return;
    }
    setState(() => _loading = true);
    try {
      await AppointmentRepository.instance.create(
        patientId: _patient!.id,
        doctorId: _doctor!.id,
        scheduledAt: _scheduledAt,
        durationMinutes: _duration,
        reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment booked')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Appointment'),
          actions: [
            TextButton(
              onPressed: _submit,
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<PatientModel>(
              initialValue: _patient,
              decoration: const InputDecoration(labelText: 'Patient *', prefixIcon: Icon(Icons.person_outline)),
              items: _patients.map((p) =>
                  DropdownMenuItem(value: p, child: Text('${p.fullName} (${p.fileNumber})'))).toList(),
              onChanged: (p) => setState(() => _patient = p),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<UserModel>(
              initialValue: _doctor,
              decoration: const InputDecoration(labelText: 'Doctor *', prefixIcon: Icon(Icons.medical_services_outlined)),
              items: _doctors.map((d) =>
                  DropdownMenuItem(value: d, child: Text('Dr. ${d.name}'))).toList(),
              onChanged: (d) => setState(() => _doctor = d),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _scheduledAt,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date == null) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_scheduledAt),
                );
                if (time == null) return;
                setState(() => _scheduledAt = DateTime(
                    date.year, date.month, date.day, time.hour, time.minute));
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCFD8DC)),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(DateFormatter.formatDateTime(_scheduledAt.toIso8601String()),
                      style: const TextStyle(fontSize: 15)),
                  const Spacer(),
                  const Icon(Icons.edit, size: 16, color: Colors.grey),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _duration,
              decoration: const InputDecoration(labelText: 'Duration', prefixIcon: Icon(Icons.timer_outlined)),
              items: [15, 20, 30, 45, 60, 90].map((m) =>
                  DropdownMenuItem(value: m, child: Text('$m minutes'))).toList(),
              onChanged: (v) => setState(() => _duration = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason for Visit'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _submit, child: const Text('Book Appointment')),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
