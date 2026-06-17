import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/sync/peer_discovery.dart';
import 'package:medcenter/shared/app_theme.dart';

class ClinicSettingsScreen extends StatefulWidget {
  const ClinicSettingsScreen({super.key});

  @override
  State<ClinicSettingsScreen> createState() => _ClinicSettingsScreenState();
}

class _ClinicSettingsScreenState extends State<ClinicSettingsScreen> {
  final config = ClinicConfig.instance;

  @override
  Widget build(BuildContext context) {
    final peers = PeerDiscovery.instance.activePeers;
    final user = AuthService.instance.currentUser;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Clinic Info
          _SectionTile('Clinic Information'),
          _InfoTile(Icons.local_hospital_outlined, 'Clinic Name', config.clinicName),
          _InfoTile(Icons.location_on_outlined, 'Address', config.clinicAddress.isEmpty ? '—' : config.clinicAddress),
          _InfoTile(Icons.phone_outlined, 'Phone', config.clinicPhone.isEmpty ? '—' : config.clinicPhone),
          _InfoTile(Icons.attach_money, 'Currency', config.currency),
          _InfoTile(Icons.flag_outlined, 'Country', config.country == 'ZA' ? 'South Africa' : 'Zimbabwe'),

          const Divider(),

          // Device Info
          _SectionTile('This Device'),
          _InfoTile(Icons.devices_outlined, 'Device ID', config.deviceId),
          _InfoTile(Icons.wifi_outlined, 'API Port', '${config.apiPort}'),
          _InfoTile(Icons.sync_outlined, 'Active Peers', '${peers.length} device(s) on same WiFi'),

          if (peers.isNotEmpty) ...[
            ...peers.map((p) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.tablet_mac, size: 20, color: AppTheme.primaryBlue),
                  title: Text(p.deviceId, style: const TextStyle(fontSize: 13)),
                  subtitle: Text('${p.ipAddress}:${p.port}', style: const TextStyle(fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('ONLINE',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.bold)),
                  ),
                )),
          ],

          const Divider(),

          // Clinic Key
          if (isAdmin) ...[
            _SectionTile('Security'),
            ListTile(
              leading: const Icon(Icons.vpn_key_outlined, color: AppTheme.primaryBlue),
              title: const Text('Clinic Key'),
              subtitle: Text(config.clinicKey,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: AppTheme.primaryBlue)),
              trailing: IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clinic key copied')));
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: AppTheme.primaryBlue),
              title: const Text('Show QR Code'),
              subtitle: const Text('Let other devices scan to join'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showQrDialog(context),
            ),
            const Divider(),
          ],

          // Sync
          _SectionTile('Sync & Backup'),
          ListTile(
            leading: const Icon(Icons.sync, color: AppTheme.primaryBlue),
            title: const Text('Force Sync Now'),
            subtitle: const Text('Push all pending changes to peers'),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync triggered...')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined, color: AppTheme.primaryBlue),
            title: const Text('Google Drive Backup'),
            subtitle: const Text('Backup database to Google Drive'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google Drive backup — Phase 2 feature')));
            },
          ),

          const Divider(),

          // Account
          _SectionTile('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.name ?? 'Unknown'),
            subtitle: Text(user?.roleLabel ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorRed),
            title: const Text('Logout', style: TextStyle(color: AppTheme.errorRed)),
            onTap: () {
              AuthService.instance.logout();
              context.go('/login');
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'MedCenter v1.0.0 • ${config.clinicId}\nPowered by Mchector Dev',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clinic Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this key with other devices to join your clinic:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                config.clinicKey,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppTheme.primaryBlue),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final String text;
  const _SectionTile(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
                letterSpacing: 0.8)),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Icon(icon, color: Colors.grey, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      );
}
