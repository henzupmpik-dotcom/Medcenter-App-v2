import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/modules/consultations/consultation_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/consultation_model.dart';
import 'package:medcenter/shared/widgets/loading_overlay.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/core/security/audit_logger.dart';

class ConsultationFormScreen extends StatefulWidget {
  final String patientId;
  final String? consultationId;
  const ConsultationFormScreen({super.key, required this.patientId, this.consultationId});

  @override
  State<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _complaintCtrl = TextEditingController();
  final _historyCtrl = TextEditingController();
  final _examinationCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _icd10Ctrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _followUp;

  // Vitals
  final _bpSysCtrl = TextEditingController();
  final _bpDiaCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _complaintCtrl, _historyCtrl, _examinationCtrl, _diagnosisCtrl,
      _icd10Ctrl, _treatmentCtrl, _notesCtrl,
      _bpSysCtrl, _bpDiaCtrl, _tempCtrl, _weightCtrl, _heightCtrl, _pulseCtrl, _spo2Ctrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  bool get _hasVitals =>
      _bpSysCtrl.text.isNotEmpty || _tempCtrl.text.isNotEmpty ||
      _weightCtrl.text.isNotEmpty || _pulseCtrl.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      VitalsModel? vitals;
      if (_hasVitals) {
        vitals = VitalsModel(
          id: KeyGenerator.uuid(),
          consultationId: '',
          patientId: widget.patientId,
          bloodPressureSys: int.tryParse(_bpSysCtrl.text),
          bloodPressureDia: int.tryParse(_bpDiaCtrl.text),
          temperature: double.tryParse(_tempCtrl.text),
          weightKg: double.tryParse(_weightCtrl.text),
          heightCm: double.tryParse(_heightCtrl.text),
          pulseRate: int.tryParse(_pulseCtrl.text),
          oxygenSaturation: int.tryParse(_spo2Ctrl.text),
          recordedAt: DateTime.now().toIso8601String(),
          recordedBy: AuthService.instance.currentUser?.id,
        );
      }

      final consultation = await ConsultationRepository.instance.create(
        patientId: widget.patientId,
        date: DateTime.now().toIso8601String().substring(0, 10),
        chiefComplaint: _complaintCtrl.text.trim().isEmpty ? null : _complaintCtrl.text.trim(),
        history: _historyCtrl.text.trim().isEmpty ? null : _historyCtrl.text.trim(),
        examination: _examinationCtrl.text.trim().isEmpty ? null : _examinationCtrl.text.trim(),
        diagnosis: _diagnosisCtrl.text.trim().isEmpty ? null : _diagnosisCtrl.text.trim(),
        icd10Code: _icd10Ctrl.text.trim().isEmpty ? null : _icd10Ctrl.text.trim(),
        treatmentPlan: _treatmentCtrl.text.trim().isEmpty ? null : _treatmentCtrl.text.trim(),
        followUpDate: _followUp?.toIso8601String().substring(0, 10),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        vitals: vitals,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Consultation saved successfully'),
            ]),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ));
        // V2: Audit log event
        AuditLogger.instance.log(
          action: 'CONSULTATION_SAVED',
          tableName: 'consultations',
          recordId: consultation.id,
          newValue: <String, dynamic>{'patient_id': widget.patientId, 'doctor_id': AuthService.instance.currentUser?.id},
        );
        context.go('/consultations/${consultation.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Save failed — please retry')),
            ]),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ));
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
          title: const Text('New Consultation'),
          actions: [
            TextButton(
              onPressed: _submit,
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader('Vital Signs'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _vitalsField(_bpSysCtrl, 'BP Systolic', 'mmHg')),
                const SizedBox(width: 10),
                Expanded(child: _vitalsField(_bpDiaCtrl, 'BP Diastolic', 'mmHg')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _vitalsField(_tempCtrl, 'Temp', '°C')),
                const SizedBox(width: 10),
                Expanded(child: _vitalsField(_pulseCtrl, 'Pulse', 'bpm')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _vitalsField(_weightCtrl, 'Weight', 'kg')),
                const SizedBox(width: 10),
                Expanded(child: _vitalsField(_heightCtrl, 'Height', 'cm')),
                const SizedBox(width: 10),
                Expanded(child: _vitalsField(_spo2Ctrl, 'SpO2', '%')),
              ]),
              const SizedBox(height: 24),
              const SectionHeader('Clinical Notes'),
              const SizedBox(height: 12),
              _textArea(_complaintCtrl, 'Chief Complaint', lines: 2),
              const SizedBox(height: 14),
              _textArea(_historyCtrl, 'History of Presenting Illness', lines: 3),
              const SizedBox(height: 14),
              _textArea(_examinationCtrl, 'Examination Findings', lines: 3),
              const SizedBox(height: 24),
              const SectionHeader('Diagnosis & Treatment'),
              const SizedBox(height: 12),
              _textArea(_diagnosisCtrl, 'Diagnosis'),
              const SizedBox(height: 14),
              _field(_icd10Ctrl, 'ICD-10 Code (optional)'),
              const SizedBox(height: 14),
              _textArea(_treatmentCtrl, 'Treatment Plan', lines: 3),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _followUp = date);
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
                    Text(
                      _followUp == null
                          ? 'Follow-up Date (optional)'
                          : 'Follow-up: ${_followUp!.toIso8601String().substring(0, 10)}',
                      style: TextStyle(
                          color: _followUp == null ? Colors.grey : Colors.black87),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              _textArea(_notesCtrl, 'Additional Notes', lines: 2),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Consultation'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vitalsField(TextEditingController ctrl, String label, String unit) =>
      TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Widget _field(TextEditingController ctrl, String label) => TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
      );

  Widget _textArea(TextEditingController ctrl, String label, {int lines = 2}) =>
      TextFormField(
        controller: ctrl,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
        ),
      );
}
