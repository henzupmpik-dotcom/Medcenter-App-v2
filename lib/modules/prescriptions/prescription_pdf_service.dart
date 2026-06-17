import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/shared/models/prescription_model.dart';

class PrescriptionPdfService {
  static Future<pw.Document> buildPdf(PrescriptionModel rx) async {
    final config = ClinicConfig.instance;
    final pdf = pw.Document(
      title: rx.prescriptionNumber,
      author: config.clinicName,
    );

    final generatedAt = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Stack(
          children: [
            // V2: CONFIDENTIAL watermark
            pw.Center(
              child: pw.Transform.rotate(
                angle: -0.5,
                child: pw.Opacity(
                  opacity: 0.06,
                  child: pw.Text(
                    'CONFIDENTIAL',
                    style: pw.TextStyle(
                      fontSize: 52,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Clinic letterhead (from Settings — never hardcoded)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        config.clinicName,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (config.clinicAddress.isNotEmpty)
                        pw.Text(
                          config.clinicAddress,
                          style: const pw.TextStyle(color: PdfColors.white70, fontSize: 9),
                        ),
                      if (config.clinicPhone.isNotEmpty)
                        pw.Text(
                          'Tel: ${config.clinicPhone}',
                          style: const pw.TextStyle(color: PdfColors.white70, fontSize: 9),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Rx # and date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PRESCRIPTION',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.Text(
                          rx.prescriptionNumber,
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Date: ${rx.date}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Patient + Doctor info
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Patient: ${rx.patientName ?? 'N/A'}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      if (rx.patientFileNumber != null)
                        pw.Text(
                          'File No: ${rx.patientFileNumber}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Medications heading
                pw.Text(
                  'Medications',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.blue100, thickness: 0.5),

                // Each medication (V2: includes route and refills)
                ...rx.items.asMap().entries.map((e) {
                  final item = e.value;
                  final i = e.key + 1;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '$i.  ${item.medicationName}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Wrap(spacing: 14, children: [
                          if (item.dosage != null)
                            _pdfTag('Dose: ${item.dosage}'),
                          if (item.frequency != null)
                            _pdfTag('Freq: ${item.frequencyLabel}'),
                          if (item.duration != null)
                            _pdfTag('Duration: ${item.duration}'),
                          if (item.route != null)
                            _pdfTag('Route: ${item.routeLabel}'),
                          if (item.quantity != null)
                            _pdfTag('Qty: ${item.quantity}'),
                          if (item.refills > 0)
                            _pdfTag('Refills: ${item.refills}'),
                        ]),
                        if (item.instructions != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'Note: ${item.instructions}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          ),
                        pw.Divider(color: PdfColors.grey300, thickness: 0.3),
                      ],
                    ),
                  );
                }),

                if (rx.notes != null && rx.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Notes: ${rx.notes}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],

                pw.Spacer(),

                // V2: Doctor signature block
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(
                        rx.doctorName != null ? 'Dr. ${rx.doctorName}' : 'Doctor',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Signature: ______________________',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ]),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text(
                        config.clinicName,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                      ),
                      pw.Text(
                        'Generated: $generatedAt',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  static pw.Widget _pdfTag(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      );

  /// Print via system print dialog (supports AirPrint / Wi-Fi printers)
  static Future<void> printPrescription(PrescriptionModel rx) async {
    final pdf = await buildPdf(rx);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  /// Share via Android share sheet (WhatsApp, Email, Telegram, etc.)
  static Future<void> sharePrescription(PrescriptionModel rx) async {
    final pdf = await buildPdf(rx);
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${rx.prescriptionNumber}.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Prescription ${rx.prescriptionNumber}',
        text: 'Prescription from ${ClinicConfig.instance.clinicName ?? "MedCenter"}',
      ),
    );
  }

  /// Export to PDF file saved on device
  static Future<String> exportToFile(PrescriptionModel rx) async {
    final pdf = await buildPdf(rx);
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${rx.prescriptionNumber}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
