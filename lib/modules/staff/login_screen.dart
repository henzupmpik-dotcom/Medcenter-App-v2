import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/shared/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pin = StringBuffer();
  bool _loading = false;
  String? _error;

  void _onDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin.write(digit);
      _error = null;
    });
    if (_pin.length >= 4) _tryLogin();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    final s = _pin.toString();
    setState(() {
      _pin.clear();
      _pin.write(s.substring(0, s.length - 1));
      _error = null;
    });
  }

  Future<void> _tryLogin() async {
    setState(() => _loading = true);
    final user = await AuthService.instance.login(_pin.toString());
    setState(() => _loading = false);

    if (user != null) {
      if (mounted) context.go('/patients');
    } else if (_pin.length >= 6) {
      setState(() {
        _error = 'Incorrect PIN';
        _pin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ClinicConfig.instance;
    final dots = _pin.length;

    return Scaffold(
      backgroundColor: AppTheme.darkBlue,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.local_hospital, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              config.clinicName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Enter your PIN to continue',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14)),
            const SizedBox(height: 40),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < dots ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
              )),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 14)),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              ),
            const Spacer(),
            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _keypadRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _keypadRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _keypadRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72),
                      _keyBtn('0'),
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: TextButton(
                          onPressed: _onDelete,
                          child: const Icon(Icons.backspace_outlined,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _keypadRow(List<String> digits) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits.map(_keyBtn).toList(),
      );

  Widget _keyBtn(String digit) => SizedBox(
        width: 72,
        height: 72,
        child: TextButton(
          onPressed: () => _onDigit(digit),
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
          ),
          child: Text(digit,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
        ),
      );
}
