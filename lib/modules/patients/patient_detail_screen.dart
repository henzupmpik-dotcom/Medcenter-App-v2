import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/modules/consultations/consultation_repository.dart';
import 'package:medcenter/modules/patients/patient_repository.dart';
import 'package:medcenter/modules/prescriptions/prescription_repository.dart';
import 'package:medcenter/modules/billing/billing_repository.dart';
import 'package:medcenter/modules/appointments/appointment_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/patient_model.dart';
import 'package:medcenter/shared/models/consultation_model.dart';
import 'package:medcenter/shared/models/prescription_model.dart';
import 'package:medcenter/shared/models/billing_model.dart';
import 'package:medcenter/shared/models/appointment_model.dart';
import 'package:medcenter/shared/widgets/empty_state.dart';
import 'package:medcenter/shared/utils/date_formatter.dart';

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PatientModel?>(
      future: PatientRepository.instance.getById(patientId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final patient = snapshot.data!;
        return _PatientDetailView(patient: patient);
      },
    );
  }
}

class _PatientDetailView extends StatefulWidget {
  final PatientModel patient;
  const _PatientDetailView({required this.patient});

  @override
  State<_PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<_PatientDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/patients/${p.id}/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'consult':
                  context.go('/patients/${p.id}/consultation/new');
                  break;
                case 'prescription':
                  context.go('/patients/${p.id}/prescription/new');
                  break;
                case 'invoice':
                  context.go('/patients/${p.id}/invoice/new');
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'consult', child: Text('New Consultation')),
              PopupMenuItem(value: 'prescription', child: Text('New Prescription')),
              PopupMenuItem(value: 'invoice', child: Text('New Invoice')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Consultations'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Billing'),
            Tab(text: 'Appointments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(patient: p),
          _ConsultationsTab(patientId: p.id),
          _PrescriptionsTab(patientId: p.id),
          _BillingTab(patientId: p.id),
          _AppointmentsTab(patientId: p.id),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/patients/${p.id}/consultation/new'),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final PatientModel patient;
  const _OverviewTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final p = patient;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Patient card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.lightBlue,
                child: Text(p.fullName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue)),
              ),
              const SizedBox(height: 12),
              Text(p.fullName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(p.fileNumber,
                    style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        _InfoCard('Personal', [
          if (p.dateOfBirth != null) _InfoRow('Date of Birth', DateFormatter.format(p.dateOfBirth!)),
          if (p.age != null) _InfoRow('Age', '${p.age} years'),
          if (p.gender != null) _InfoRow('Gender', p.gender!),
          if (p.nationalId != null) _InfoRow('National ID', p.nationalId!),
          if (p.bloodGroup != null) _InfoRow('Blood Group', p.bloodGroup!),
        ]),
        _InfoCard('Contact', [
          if (p.phone != null) _InfoRow('Phone', p.phone!),
          if (p.email != null) _InfoRow('Email', p.email!),
          if (p.address != null) _InfoRow('Address', p.address!),
        ]),
        if (p.nextOfKinName != null)
          _InfoCard('Next of Kin', [
            _InfoRow('Name', p.nextOfKinName!),
            if (p.nextOfKinPhone != null) _InfoRow('Phone', p.nextOfKinPhone!),
            if (p.nextOfKinRelation != null) _InfoRow('Relation', p.nextOfKinRelation!),
          ]),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _InfoCard(this.title, this.rows);

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue)),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );
}

// ── Consultations Tab ─────────────────────────────────────────────────────────
class _ConsultationsTab extends StatelessWidget {
  final String patientId;
  const _ConsultationsTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConsultationModel>>(
      future: ConsultationRepository.instance.getForPatient(patientId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return EmptyState(icon: Icons.notes, message: 'No consultations yet');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final c = list[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.lightBlue,
                  child: Icon(Icons.medical_services_outlined, color: AppTheme.primaryBlue, size: 18),
                ),
                title: Text(c.diagnosis ?? c.chiefComplaint ?? 'Consultation',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(DateFormatter.format(c.date)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/consultations/${c.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Prescriptions Tab ─────────────────────────────────────────────────────────
class _PrescriptionsTab extends StatelessWidget {
  final String patientId;
  const _PrescriptionsTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrescriptionModel>>(
      future: PrescriptionRepository.instance.getForPatient(patientId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return EmptyState(icon: Icons.medication_outlined, message: 'No prescriptions yet');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final rx = list[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.medication, color: Color(0xFF2E7D32), size: 18),
                ),
                title: Text(rx.prescriptionNumber,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${rx.items.length} medication(s) • ${DateFormatter.format(rx.date)}'),
                trailing: _StatusChip(rx.status),
                onTap: () => context.go('/prescriptions/${rx.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Billing Tab ───────────────────────────────────────────────────────────────
class _BillingTab extends StatelessWidget {
  final String patientId;
  const _BillingTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InvoiceModel>>(
      future: BillingRepository.instance.getForPatient(patientId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return EmptyState(icon: Icons.receipt_outlined, message: 'No invoices yet');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final inv = list[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF8E1),
                  child: Icon(Icons.receipt, color: Color(0xFFF57F17), size: 18),
                ),
                title: Text(inv.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('R ${inv.totalAmount.toStringAsFixed(2)} • ${DateFormatter.format(inv.date)}'),
                trailing: _StatusChip(inv.status),
                onTap: () => context.go('/billing/${inv.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Appointments Tab ──────────────────────────────────────────────────────────
class _AppointmentsTab extends StatelessWidget {
  final String patientId;
  const _AppointmentsTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppointmentModel>>(
      future: AppointmentRepository.instance.getForPatient(patientId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return EmptyState(icon: Icons.calendar_today, message: 'No appointments yet');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final apt = list[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.lightBlue,
                  child: Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 18),
                ),
                title: Text(apt.reason ?? 'Appointment',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(DateFormatter.formatDateTime(apt.scheduledAt)),
                trailing: _StatusChip(apt.status),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.statusColor(status).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.statusColor(status),
            letterSpacing: 0.5,
          ),
        ),
      );
}
