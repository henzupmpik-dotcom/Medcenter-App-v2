import 'package:flutter/material.dart';
import 'package:medcenter/modules/prescriptions/prescription_repository.dart';
import 'package:medcenter/modules/prescriptions/prescription_pdf_service.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/prescription_model.dart';
import 'package:medcenter/shared/utils/date_formatter.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final String prescriptionId;
  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PrescriptionModel?>(
      future: PrescriptionRepository.instance.getById(prescriptionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final rx = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(rx.prescriptionNumber),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Export PDF',
                onPressed: () => PrescriptionPdfService.printPrescription(rx),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.medication, color: AppTheme.primaryBlue, size: 18),
                      const SizedBox(width: 8),
                      Text(rx.prescriptionNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                              fontSize: 16)),
                      const Spacer(),
                      _chip(rx.status),
                    ]),
                    if (rx.patientName != null) ...[
                      const SizedBox(height: 8),
                      Text(rx.patientName!,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (rx.patientFileNumber != null)
                        Text(rx.patientFileNumber!,
                            style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                    ],
                    const SizedBox(height: 8),
                    Text('Date: ${DateFormatter.format(rx.date)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    if (rx.doctorName != null)
                      Text('Dr. ${rx.doctorName}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    if (rx.isRepeat)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9C4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('REPEAT PRESCRIPTION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF57F17))),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              // Medications
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text('Medications',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                        letterSpacing: 0.5)),
              ),
              ...rx.items.asMap().entries.map((e) => _MedCard(item: e.value, index: e.key)),
              if (rx.notes != null) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Notes',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue)),
                      const SizedBox(height: 8),
                      Text(rx.notes!, style: const TextStyle(fontSize: 14, height: 1.5)),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // V2: Export / Share actions per spec
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => PrescriptionPdfService.printPrescription(rx),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Print'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => PrescriptionPdfService.sharePrescription(rx),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('WhatsApp / Share'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => PrescriptionPdfService.exportToFile(rx),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Export to PDF'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.statusColor(status).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(status.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.statusColor(status))),
      );
}

class _MedCard extends StatelessWidget {
  final PrescriptionItemModel item;
  final int index;
  const _MedCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.lightBlue,
                child: Text('${index + 1}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.medicationName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (item.quantity != null)
                Text('Qty: ${item.quantity}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            if (item.dosage != null || item.frequency != null) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (item.dosage != null)
                  _tag('💊 \${item.dosage}'),
                if (item.frequency != null)
                  _tag('🕐 \${item.frequencyLabel}'),
                if (item.duration != null)
                  _tag('📅 \${item.duration}'),
                if (item.route != null)
                  _tag('🩺 \${item.routeLabel}'),
                if (item.refills > 0)
                  _tag('🔁 \${item.refills} refill\${item.refills > 1 ? "s" : ""}'),
              ]),
            ],
            if (item.instructions != null) ...[
              const SizedBox(height: 6),
              Text(item.instructions!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ]),
        ),
      );

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
}
