import 'package:flutter/material.dart';
import 'package:medcenter/shared/app_theme.dart';

class JoinClinicScreen extends StatefulWidget {
  const JoinClinicScreen({super.key});

  @override
  State<JoinClinicScreen> createState() => _JoinClinicScreenState();
}

class _JoinClinicScreenState extends State<JoinClinicScreen> {
  final _keyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String _role = 'reception';
  bool _loading = false;

  @override
  void dispose() {
    _keyCtrl.dispose(); _nameCtrl.dispose(); _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_keyCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter clinic key and your name')),
      );
      return;
    }
    setState(() => _loading = true);
    // TODO: Full join flow — UDP peer discovery, pull DB from host
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Searching for clinic on WiFi...'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Existing Clinic')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppTheme.primaryBlue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Both devices must be on the same WiFi network. Get the Clinic Key from the main device.',
                  style: TextStyle(color: AppTheme.primaryBlue, fontSize: 13),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _keyCtrl,
            decoration: const InputDecoration(
              labelText: 'Clinic Key',
              hintText: 'XXXX-XXXX-XXXX-XXXX',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
            style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(
              labelText: 'Your Role',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
              DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
              DropdownMenuItem(value: 'reception', child: Text('Receptionist')),
              DropdownMenuItem(value: 'admin', child: Text('Administrator')),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Set Your PIN',
              prefixIcon: Icon(Icons.lock_outline),
              counterText: '',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _join,
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.wifi),
              label: Text(_loading ? 'Connecting...' : 'Connect to Clinic'),
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: Text('— or —', style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // QR scan to pre-fill key
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open camera to scan clinic QR code')),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Code'),
          ),
        ],
      ),
    );
  }
}
