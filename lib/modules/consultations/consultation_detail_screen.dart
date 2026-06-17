import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/modules/consultations/consultation_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/consultation_model.dart';
import 'package:medcenter/shared/utils/date_formatter.dart';

class ConsultationDetailScreen extends StatelessWidget {
  final String consultationId;
  const ConsultationDetailScreen({super.key, required this.consultationId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConsultationModel?>(
      future: ConsultationRepository.instance.getById(consultationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final c = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Consultation'),
            actions: [
              if (c.patientId.isNotEmpty)
                TextButton(
                  onPressed: () => context.go('/patients/${c.patientId}/prescription/new'),
                  child: const Text('Rx', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          body: FutureBuilder<VitalsModel?>(
            future: ConsultationRepository.instance.getVitalsForConsultation(consultationId),
            builder: (context, vitalsSnap) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryBlue),
                          const SizedBox(width: 6),
                          Text(DateFormatter.format(c.date),
                              style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (c.doctorName != null)
                            Text('Dr. ${c.doctorName}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ]),
                        if (c.patientName != null) ...[
                          const SizedBox(height: 4),
                          Text(c.patientName!,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (c.patientFileNumber != null)
                            Text(c.patientFileNumber!,
                                style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                        ],
                      ]),
                    ),
                  ),
                  // Vitals
                  if (vitalsSnap.hasData && vitalsSnap.data != null) ...[
                    const SizedBox(height: 8),
                    _VitalsCard(vitals: vitalsSnap.data!),
                  ],
                  const SizedBox(height: 8),
                  // Clinical sections
                  if (c.chiefComplaint != null)
                    _Section('Chief Complaint', c.chiefComplaint!),
                  if (c.history != null)
                    _Section('History', c.history!),
                  if (c.examination != null)
                    _Section('Examination', c.examination!),
                  if (c.diagnosis != null)
                    _Section('Diagnosis', c.diagnosis!, highlight: true),
                  if (c.icd10Code != null)
                    _Section('ICD-10', c.icd10Code!),
                  if (c.treatmentPlan != null)
                    _Section('Treatment Plan', c.treatmentPlan!),
                  if (c.followUpDate != null)
                    _Section('Follow-up', DateFormatter.format(c.followUpDate!)),
                  if (c.notes != null)
                    _Section('Notes', c.notes!),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final bool highlight;
  const _Section(this.title, this.content, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(content,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                    color: highlight ? Colors.black87 : Colors.black54,
                    height: 1.5,
                  )),
            ],
          ),
        ),
      );
}

class _VitalsCard extends StatelessWidget {
  final VitalsModel vitals;
  const _VitalsCard({required this.vitals});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vital Signs',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Wrap(spacing: 16, runSpacing: 10, children: [
                if (vitals.bloodPressureSys != null)
                  _VitalChip('BP',
                      '${vitals.bloodPressureSys}/${vitals.bloodPressureDia} mmHg',
                      Icons.favorite_outline),
                if (vitals.temperature != null)
                  _VitalChip('Temp', '${vitals.temperature}°C', Icons.thermostat),
                if (vitals.pulseRate != null)
                  _VitalChip('Pulse', '${vitals.pulseRate} bpm', Icons.monitor_heart_outlined),
                if (vitals.weightKg != null)
                  _VitalChip('Weight', '${vitals.weightKg} kg', Icons.scale_outlined),
                if (vitals.heightCm != null)
                  _VitalChip('Height', '${vitals.heightCm} cm', Icons.height),
                if (vitals.oxygenSaturation != null)
                  _VitalChip('SpO2', '${vitals.oxygenSaturation}%', Icons.air),
                if (vitals.bmi != null)
                  _VitalChip('BMI', vitals.bmi!, Icons.monitor_weight_outlined),
              ]),
            ],
          ),
        ),
      );
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _VitalChip(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.lightBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
          ]),
        ]),
      );
}
