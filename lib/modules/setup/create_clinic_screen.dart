import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/widgets/loading_overlay.dart';

class CreateClinicScreen extends StatefulWidget {
  const CreateClinicScreen({super.key});

  @override
  State<CreateClinicScreen> createState() => _CreateClinicScreenState();
}

class _CreateClinicScreenState extends State<CreateClinicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  String _country = 'ZA';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _adminNameCtrl.dispose(); _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final clinicId = KeyGenerator.generateClinicId();
      final clinicKey = KeyGenerator.generateClinicKey();
      final deviceId = KeyGenerator.generateDeviceId();

      await ClinicConfig.instance.setAll({
        'clinic_id': clinicId,
        'clinic_key': clinicKey,
        'clinic_name': _nameCtrl.text.trim(),
        'clinic_address': _addressCtrl.text.trim(),
        'clinic_phone': _phoneCtrl.text.trim(),
        'clinic_email': _emailCtrl.text.trim(),
        'country': _country,
        'currency': _country == 'ZW' ? 'USD' : 'ZAR',
        'device_id': deviceId,
        'device_name': 'Main Device',
        'api_port': '8080',
      });

      await AuthService.instance.createAdminUser(
        name: _adminNameCtrl.text.trim(),
        pin: _pinCtrl.text,
        deviceId: deviceId,
      );

      if (mounted) {
        _showClinicKey(clinicKey);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showClinicKey(String key) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Clinic Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your clinic key (share with other devices to join this clinic):'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppTheme.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Save this key. Other devices need it to join.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Continue to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create New Clinic')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SectionHeader('Clinic Information'),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Clinic Name', required: true),
              const SizedBox(height: 14),
              _field(_addressCtrl, 'Address'),
              const SizedBox(height: 14),
              _field(_phoneCtrl, 'Phone Number', keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _field(_emailCtrl, 'Email', keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _country,
                decoration: const InputDecoration(labelText: 'Country & Currency'),
                items: const [
                  DropdownMenuItem(value: 'ZA', child: Text('South Africa (ZAR)')),
                  DropdownMenuItem(value: 'ZW', child: Text('Zimbabwe (USD)')),
                ],
                onChanged: (v) => setState(() => _country = v!),
              ),
              const SizedBox(height: 28),
              _SectionHeader('Admin Account'),
              const SizedBox(height: 12),
              _field(_adminNameCtrl, 'Admin Name', required: true),
              const SizedBox(height: 14),
              _field(_pinCtrl, 'PIN (6 digits)', required: true,
                  keyboard: TextInputType.number,
                  obscure: true,
                  maxLength: 6,
                  validator: (v) {
                    if (v == null || v.length < 4) return 'PIN must be 4-6 digits';
                    if (!RegExp(r'^\d+$').hasMatch(v)) return 'Digits only';
                    return null;
                  }),
              const SizedBox(height: 14),
              _field(_confirmPinCtrl, 'Confirm PIN', required: true,
                  keyboard: TextInputType.number,
                  obscure: true,
                  maxLength: 6,
                  validator: (v) {
                    if (v != _pinCtrl.text) return 'PINs do not match';
                    return null;
                  }),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Create Clinic'),
                ),
              ),
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
    bool obscure = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        obscureText: obscure,
        maxLength: maxLength,
        decoration: InputDecoration(labelText: label, counterText: ''),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null),
      );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBlue,
          letterSpacing: 0.5,
        ),
      );
}
