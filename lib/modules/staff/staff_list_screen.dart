import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/database/database_helper.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/user_model.dart';
import 'package:medcenter/shared/widgets/loading_overlay.dart';

// ── Staff List ────────────────────────────────────────────────────────────────
class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await AuthService.instance.getAllUsers();
    setState(() { _users = users; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final canManage = AuthService.instance.hasPermission('staff.manage');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () async {
                await context.push('/staff/new');
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? EmptyState(
                  icon: Icons.badge_outlined,
                  message: 'No staff members yet',
                  action: canManage
                      ? ElevatedButton.icon(
                          onPressed: () async {
                            await context.push('/staff/new');
                            _load();
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Staff Member'),
                        )
                      : null,
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final user = _users[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _roleColor(user.role).withValues(alpha: 0.15),
                          child: Text(user.name[0].toUpperCase(),
                              style: TextStyle(
                                  color: _roleColor(user.role),
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(user.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(user.roleLabel),
                        trailing: canManage
                            ? IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () async {
                                  await context.push('/staff/${user.id}/edit');
                                  _load();
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/staff/new');
                _load();
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Staff'),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return AppTheme.errorRed;
      case 'doctor': return AppTheme.primaryBlue;
      case 'nurse': return const Color(0xFF00897B);
      case 'reception': return AppTheme.warningAmber;
      default: return Colors.grey;
    }
  }
}

// ── Staff Form ────────────────────────────────────────────────────────────────
class StaffFormScreen extends StatefulWidget {
  final String? userId;
  const StaffFormScreen({super.key, this.userId});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  String _role = 'reception';
  bool _loading = false;
  bool get _isEdit => widget.userId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    final rows = await DatabaseHelper.instance.query(
        'users', where: 'id = ?', whereArgs: [widget.userId!], limit: 1);
    if (rows.isNotEmpty) {
      final u = UserModel.fromMap(rows.first);
      _nameCtrl.text = u.name;
      _role = u.role;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _pinCtrl.dispose(); _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name is required')));
      return;
    }
    if (!_isEdit && _pinCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN must be at least 4 digits')));
      return;
    }
    if (!_isEdit && _pinCtrl.text != _confirmPinCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match')));
      return;
    }

    setState(() => _loading = true);
    try {
      final now = DateTime.now().toIso8601String();
      if (_isEdit) {
        final updateData = <String, dynamic>{
          'name': _nameCtrl.text.trim(),
          'role': _role,
          'updated_at': now,
        };
        if (_pinCtrl.text.length >= 4) {
          updateData['pin_hash'] = KeyGenerator.hashPin(_pinCtrl.text);
        }
        await DatabaseHelper.instance.update(
            'users', updateData, where: 'id = ?', whereArgs: [widget.userId!]);
      } else {
        await DatabaseHelper.instance.insert('users', {
          'id': KeyGenerator.uuid(),
          'name': _nameCtrl.text.trim(),
          'role': _role,
          'pin_hash': KeyGenerator.hashPin(_pinCtrl.text),
          'device_id': ClinicConfig.instance.deviceId,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
          'sync_version': 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEdit ? 'Staff updated' : 'Staff member added')));
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
          title: Text(_isEdit ? 'Edit Staff Member' : 'Add Staff Member'),
          actions: [
            TextButton(
              onPressed: _submit,
              child: const Text('SAVE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                  labelText: 'Role', prefixIcon: Icon(Icons.badge_outlined)),
              items: const [
                DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                DropdownMenuItem(value: 'reception', child: Text('Receptionist')),
                DropdownMenuItem(value: 'admin', child: Text('Administrator')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 24),
            Text(
              _isEdit ? 'Change PIN (leave blank to keep current)' : 'Set PIN *',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                  fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  labelText: 'PIN (4–6 digits)',
                  prefixIcon: Icon(Icons.lock_outline),
                  counterText: ''),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  prefixIcon: Icon(Icons.lock_outline),
                  counterText: ''),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(_isEdit ? 'Update Staff Member' : 'Add Staff Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
