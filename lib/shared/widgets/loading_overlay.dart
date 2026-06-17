import 'package:flutter/material.dart';
import 'package:medcenter/shared/app_theme.dart';

// ── Loading Overlay ───────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      );
}

// ── Empty State ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
              ),
              if (action != null) ...[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          ),
        ),
      );
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionHeader(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      );
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class InfoRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;
  const InfoRowWidget(this.label, this.value, {super.key, this.labelWidth = 120});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryBlue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c, size: 24),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: c)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ── Confirm Dialog ────────────────────────────────────────────────────────────
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  Color? confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppTheme.primaryBlue),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
