import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/modules/billing/billing_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/billing_model.dart';

class PaymentScreen extends StatefulWidget {
  final String invoiceId;
  const PaymentScreen({super.key, required this.invoiceId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method = 'cash';
  bool _loading = false;
  InvoiceModel? _invoice;

  static const _methods = [
    ('cash', 'Cash'),
    ('card', 'Card (Yoco)'),
    ('eft', 'EFT'),
    ('medical_aid', 'Medical Aid'),
    ('insurance', 'Insurance'),
  ];

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoice() async {
    final inv = await BillingRepository.instance.getInvoice(widget.invoiceId);
    if (mounted) {
      setState(() {
        _invoice = inv;
        if (inv != null) {
          _amountCtrl.text = inv.balance.toStringAsFixed(2);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final amount = double.parse(_amountCtrl.text);
      await BillingRepository.instance.recordPayment(
        invoiceId: widget.invoiceId,
        patientId: _invoice!.patientId,
        amount: amount,
        method: _method,
        reference: _referenceCtrl.text.trim().isEmpty ? null : _referenceCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Payment recorded successfully'),
            ]),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/billing/${widget.invoiceId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Payment failed — please retry')),
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Record Payment'),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: _invoice == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Invoice summary card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_invoice!.invoiceNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (_invoice!.patientName != null)
                              Text(_invoice!.patientName!,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A))),
                          ]),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('R ${_invoice!.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Balance: R ${_invoice!.balance.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFC62828))),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    decoration: const InputDecoration(
                      labelText: 'Amount Received *',
                      prefixText: 'R ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final d = double.tryParse(v);
                      if (d == null || d <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Payment method
                  DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: _methods.map((m) =>
                        DropdownMenuItem(value: m.$1, child: Text(m.$2))).toList(),
                    onChanged: (v) => setState(() => _method = v ?? 'cash'),
                  ),
                  const SizedBox(height: 14),

                  // Reference number (optional)
                  TextFormField(
                    controller: _referenceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reference / Receipt No. (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Record Payment', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
