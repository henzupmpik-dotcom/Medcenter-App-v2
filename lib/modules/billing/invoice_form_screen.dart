import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/modules/billing/billing_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/widgets/loading_overlay.dart';

// ── Invoice Form ──────────────────────────────────────────────────────────────
class InvoiceFormScreen extends StatefulWidget {
  final String patientId;
  final String? consultationId;
  const InvoiceFormScreen({super.key, required this.patientId, this.consultationId});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  bool _loading = false;
  final _discountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<_LineItem> _items = [_LineItem()];

  @override
  void dispose() {
    _discountCtrl.dispose(); _notesCtrl.dispose();
    for (final i in _items) { i.dispose(); }
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, i) {
    final q = int.tryParse(i.qtyCtrl.text) ?? 1;
    final p = double.tryParse(i.priceCtrl.text) ?? 0;
    return sum + q * p;
  });

  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _subtotal - _discount;

  Future<void> _submit() async {
    if (_items.any((i) => i.descCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all item descriptions')));
      return;
    }
    setState(() => _loading = true);
    try {
      final items = _items.map((i) => {
        'description': i.descCtrl.text.trim(),
        'quantity': int.tryParse(i.qtyCtrl.text) ?? 1,
        'unit_price': double.tryParse(i.priceCtrl.text) ?? 0.0,
      }).toList();

      final invoice = await BillingRepository.instance.createInvoice(
        patientId: widget.patientId,
        consultationId: widget.consultationId,
        items: items,
        discount: _discount,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${invoice.invoiceNumber} created')));
        context.go('/billing/${invoice.id}');
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
          title: const Text('New Invoice'),
          actions: [
            TextButton(
              onPressed: _submit,
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader('Line Items'),
            const SizedBox(height: 12),
            ..._items.asMap().entries.map((e) => _LineItemCard(
                  item: e.value,
                  index: e.key,
                  onRemove: _items.length > 1
                      ? () => setState(() { e.value.dispose(); _items.removeAt(e.key); })
                      : null,
                  onChanged: () => setState(() {}),
                )),
            OutlinedButton.icon(
              onPressed: () => setState(() => _items.add(_LineItem())),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
            const SizedBox(height: 24),
            const SectionHeader('Totals'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _TotalRow('Subtotal', 'R ${_subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Expanded(child: Text('Discount (R)')),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _discountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          prefixText: 'R ',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ]),
                  const Divider(height: 20),
                  _TotalRow('TOTAL', 'R ${_total.toStringAsFixed(2)}', bold: true),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (medical aid, etc.)'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _submit, child: const Text('Create Invoice')),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _LineItem {
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();
  void dispose() { descCtrl.dispose(); qtyCtrl.dispose(); priceCtrl.dispose(); }
}

class _LineItemCard extends StatelessWidget {
  final _LineItem item;
  final int index;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;
  const _LineItemCard({required this.item, required this.index, this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              Text('Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue, fontSize: 13)),
              const Spacer(),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close, size: 18, color: Colors.red),
                ),
            ]),
            const SizedBox(height: 8),
            TextFormField(
              controller: item.descCtrl,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(labelText: 'Description *'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(
                controller: item.qtyCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(labelText: 'Qty'),
              )),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(
                controller: item.priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(labelText: 'Unit Price', prefixText: 'R '),
              )),
            ]),
          ]),
        ),
      );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _TotalRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 15 : 14)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 15 : 14, color: bold ? AppTheme.primaryBlue : null)),
        ],
      );
}
