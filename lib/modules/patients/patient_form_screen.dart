import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/modules/patients/patient_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/patient_model.dart';
import 'package:medcenter/shared/widgets/loading_overlay.dart';

class PatientFormScreen extends StatefulWidget {
  final String? patientId;
  const PatientFormScreen({super.key, this.patientId});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isEdit = false;
  PatientModel? _existingPatient;

  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _kinNameCtrl = TextEditingController();
  final _kinPhoneCtrl = TextEditingController();
  final _kinRelationCtrl = TextEditingController();
  String? _gender;
  String? _bloodGroup;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.patientId != null;
    if (_isEdit) _loadPatient();
  }

  Future<void> _loadPatient() async {
    setState(() => _loading = true);
    _existingPatient = await PatientRepository.instance.getById(widget.patientId!);
    if (_existingPatient != null) {
      final p = _existingPatient!;
      _nameCtrl.text = p.fullName;
      _dobCtrl.text = p.dateOfBirth ?? '';
      _nationalIdCtrl.text = p.nationalId ?? '';
      _phoneCtrl.text = p.phone ?? '';
      _emailCtrl.text = p.email ?? '';
      _addressCtrl.text = p.address ?? '';
      _kinNameCtrl.text = p.nextOfKinName ?? '';
      _kinPhoneCtrl.text = p.nextOfKinPhone ?? '';
      _kinRelationCtrl.text = p.nextOfKinRelation ?? '';
      _gender = p.gender;
      _bloodGroup = p.bloodGroup;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _dobCtrl, _nationalIdCtrl, _phoneCtrl,
        _emailCtrl, _addressCtrl, _kinNameCtrl, _kinPhoneCtrl, _kinRelationCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isEdit && _existingPatient != null) {
        await PatientRepository.instance.update(_existingPatient!.copyWith(
          fullName: _nameCtrl.text.trim(),
          dateOfBirth: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
          gender: _gender,
          nationalId: _nationalIdCtrl.text.trim().isEmpty ? null : _nationalIdCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          nextOfKinName: _kinNameCtrl.text.trim().isEmpty ? null : _kinNameCtrl.text.trim(),
          nextOfKinPhone: _kinPhoneCtrl.text.trim().isEmpty ? null : _kinPhoneCtrl.text.trim(),
          nextOfKinRelation: _kinRelationCtrl.text.trim().isEmpty ? null : _kinRelationCtrl.text.trim(),
          bloodGroup: _bloodGroup,
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Patient updated successfully')));
          context.pop();
        }
      } else {
        final patient = await PatientRepository.instance.create(
          fullName: _nameCtrl.text.trim(),
          dateOfBirth: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
          gender: _gender,
          nationalId: _nationalIdCtrl.text.trim().isEmpty ? null : _nationalIdCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          nextOfKinName: _kinNameCtrl.text.trim().isEmpty ? null : _kinNameCtrl.text.trim(),
          nextOfKinPhone: _kinPhoneCtrl.text.trim().isEmpty ? null : _kinPhoneCtrl.text.trim(),
          nextOfKinRelation: _kinRelationCtrl.text.trim().isEmpty ? null : _kinRelationCtrl.text.trim(),
          bloodGroup: _bloodGroup,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Patient ${patient.fileNumber} registered')));
          context.go('/patients/${patient.id}');
        }
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
          title: Text(_isEdit ? 'Edit Patient' : 'Register Patient'),
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
              const SectionHeader('Personal Information'),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Full Name *', required: true),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _dobCtrl.text = date.toIso8601String().substring(0, 10);
                  }
                },
                child: AbsorbPointer(
                  child: _field(_dobCtrl, 'Date of Birth',
                      suffixIcon: const Icon(Icons.calendar_today)),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other'].map((g) =>
                    DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 14),
              _field(_nationalIdCtrl, 'National ID / Passport'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _bloodGroup,
                decoration: const InputDecoration(labelText: 'Blood Group'),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((b) =>
                    DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _bloodGroup = v),
              ),
              const SizedBox(height: 24),
              const SectionHeader('Contact Details'),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone Number', keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _field(_emailCtrl, 'Email', keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _field(_addressCtrl, 'Address', maxLines: 2),
              const SizedBox(height: 24),
              const SectionHeader('Next of Kin'),
              const SizedBox(height: 12),
              _field(_kinNameCtrl, 'Name'),
              const SizedBox(height: 14),
              _field(_kinPhoneCtrl, 'Phone', keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _field(_kinRelationCtrl, 'Relationship (e.g. Spouse, Parent)'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEdit ? 'Update Patient' : 'Register Patient'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    Widget? suffixIcon,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      );
}
