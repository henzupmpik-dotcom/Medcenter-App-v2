import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/core/security/key_generator.dart';
import 'package:medcenter/modules/prescriptions/prescription_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/prescription_model.dart';
import 'package:medcenter/shared/widgets/section_header.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String patientId;
  final String? consultationId;

  const PrescriptionFormScreen({
    super.key,
    required this.patientId,
    this.consultationId,
  });

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  final _notesCtrl = TextEditingController();
  final List<_MedItem> _medications = [_MedItem()];

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final m in _medications) { m.dispose(); }
    super.dispose();
  }

  void _addMedication() => setState(() => _medications.add(_MedItem()));

  void _removeMedication(int index) {
    if (_medications.length == 1) return;
    setState(() {
      _medications[index].dispose();
      _medications.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final doctor = AuthService.instance.currentUser;
      final items = _medications.map((m) => PrescriptionItemModel(
        id: KeyGenerator.uuid(),
        prescriptionId: '',
        medicationName: m.drugCtrl.text.trim(),
        dosage: m.dosageCtrl.text.trim().isEmpty ? null : m.dosageCtrl.text.trim(),
        frequency: m.frequency,
        duration: m.durationCtrl.text.trim().isEmpty ? null : m.durationCtrl.text.trim(),
        route: m.route,
        refills: m.refills,
        instructions: m.instructionsCtrl.text.trim().isEmpty ? null : m.instructionsCtrl.text.trim(),
        quantity: int.tryParse(m.quantityCtrl.text),
      )).toList();

      final rx = await PrescriptionRepository.instance.create(
        patientId: widget.patientId,
        doctorId: doctor?.id ?? '',
        consultationId: widget.consultationId,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        items: items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Prescription saved successfully'),
            ]),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/prescriptions/${rx.id}');
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
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = AuthService.instance.currentUser;
    final today = DateTime.now();
    final dateStr = '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('New Prescription'),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save, color: Colors.white, size: 18),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Auto-filled header
            Card(
              color: AppTheme.darkBlue.withValues(alpha: 0.06),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.person_outlined, size: 18, color: Color(0xFF546E7A)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prescribing Doctor: ${doctor?.name ?? 'Unknown'}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Date: $dateStr',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF78909C))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Medications
            SectionHeader('Medications'),
            const SizedBox(height: 8),
            ...List.generate(_medications.length, (i) => _MedicationCard(
              key: ValueKey(i),
              item: _medications[i],
              index: i,
              canRemove: _medications.length > 1,
              onRemove: () => _removeMedication(i),
            )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addMedication,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Another Medication'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.darkBlue,
                side: BorderSide(color: AppTheme.darkBlue.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            SectionHeader('Additional Notes (Optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Course of treatment, special instructions...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Prescription', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MedItem {
  final drugCtrl = TextEditingController();
  final dosageCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();
  final instructionsCtrl = TextEditingController();
  String? frequency = 'once_daily';
  String? route = 'oral';
  int refills = 0;

  void dispose() {
    drugCtrl.dispose();
    dosageCtrl.dispose();
    durationCtrl.dispose();
    quantityCtrl.dispose();
    instructionsCtrl.dispose();
  }
}

class _MedicationCard extends StatefulWidget {
  final _MedItem item;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  const _MedicationCard({
    super.key,
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  State<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<_MedicationCard> {
  static const _frequencies = [
    ('once_daily', 'Once daily'),
    ('twice_daily', 'Twice daily'),
    ('three_daily', 'Three times daily'),
    ('as_needed', 'As needed'),
  ];

  static const _routes = [
    ('oral', 'Oral'),
    ('iv', 'IV'),
    ('im', 'IM'),
    ('topical', 'Topical'),
    ('inhaled', 'Inhaled'),
  ];

  @override
  Widget build(BuildContext context) {
    final m = widget.item;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.darkBlue.withValues(alpha: 0.12),
                  child: Text('${widget.index + 1}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                ),
                const SizedBox(width: 8),
                const Text('Medication', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (widget.canRemove)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Drug name
            TextFormField(
              controller: m.drugCtrl,
              decoration: const InputDecoration(
                labelText: 'Drug / Medication Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Drug name is required' : null,
            ),
            const SizedBox(height: 10),

            // Dosage + Route
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: m.dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage *',
                    hintText: 'e.g. 500mg',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: m.route,
                  decoration: const InputDecoration(
                    labelText: 'Route',
                    border: OutlineInputBorder(),
                  ),
                  items: _routes.map((r) =>
                      DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
                  onChanged: (v) => setState(() => m.route = v),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            // Frequency
            DropdownButtonFormField<String>(
              initialValue: m.frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: _frequencies.map((f) =>
                  DropdownMenuItem(value: f.$1, child: Text(f.$2))).toList(),
              onChanged: (v) => setState(() => m.frequency = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 10),

            // Duration + Quantity
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: m.durationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Duration *',
                    hintText: 'e.g. 7 days',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: m.quantityCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quantity *',
                    hintText: 'e.g. 21',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ]),
            const SizedBox(height: 10),

            // Refills
            Row(children: [
              const Text('Refills:', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: m.refills > 0 ? () => setState(() => m.refills--) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${m.refills}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF2E7D32)),
                onPressed: () => setState(() => m.refills++),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 10),

            // Instructions
            TextFormField(
              controller: m.instructionsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Instructions (optional)',
                hintText: 'e.g. Take after meals, avoid alcohol',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
