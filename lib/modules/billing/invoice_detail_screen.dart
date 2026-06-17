import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medcenter/modules/billing/billing_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/billing_model.dart';
import 'package:medcenter/shared/utils/date_formatter.dart';
import 'package:medcenter/shared/widgets/info_row.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<<InvoiceDetailScreen> {
  InvoiceModel? _invoice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final inv = await BillingRepository.instance.getInvoice(widget.invoiceId);
      if (mounted) setState(() { _invoice = inv; _loading = false; });
    } catch (e) {
      debugPrint('InvoiceDetailScreen _load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markPaid(InvoiceModel inv) async {
    try {
      await BillingRepository.instance.markPaid(inv.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Invoice marked as paid'),
            ]),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_invoice != null ? _invoice!.invoiceNumber : 'Invoice'),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_invoice != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) {
                if (v == 'pay') context.go('/billing/${_invoice!.id}/pay');
                if (v == 'edit') context.go('/billing/${_invoice!.id}/edit');
              },
              itemBuilder: (_) => [
                if (_invoice!.status != 'paid')
                  const PopupMenuItem(value: 'pay', child: Text('Record Payment')),
                const PopupMenuItem(value: 'edit', child: Text('Edit Invoice')),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invoice == null
              ? const Center(child: Text('Invoice not found'))
              : _InvoiceBody(
                  invoice: _invoice!,
                  onMarkPaid: () => _markPaid(_invoice!),
                ),
    );
  }
}

class _InvoiceBody extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onMarkPaid;

  const _InvoiceBody({required this.invoice, required this.onMarkPaid});

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return const Color(0xFF2E7D32);
      case 'partial': return const Color(0xFFE65100);
      case 'overdue': return const Color(0xFFC62828);
      default: return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_ZA', symbol: 'R ');
    final statusColor = _statusColor(invoice.status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(invoice.invoiceNumber,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        invoice.status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (invoice.patientName != null)
                  InfoRow(label: 'Patient', value: invoice.patientName!),
                if (invoice.patientFileNumber != null)
                  InfoRow(label: 'File No.', value: invoice.patientFileNumber!),
                InfoRow(label: 'Date', value: DateFormatter.format(invoice.date)),
                if (invoice.dueDate != null)
                  InfoRow(label: 'Due Date', value: DateFormatter.format(invoice.dueDate!)),
                if (invoice.paidAt != null)
                  InfoRow(label: 'Paid On', value: DateFormatter.format(invoice.paidAt!)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Line Items',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF546E7A))),
                const SizedBox(height: 10),
                Row(children: const [
                  Expanded(flex: 4, child: Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF78909C)))),
                  SizedBox(width: 8),
                  SizedBox(width: 36, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF78909C)), textAlign: TextAlign.center)),
                  SizedBox(width: 8),
                  SizedBox(width: 72, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF78909C)), textAlign: TextAlign.right)),
                  SizedBox(width: 8),
                  SizedBox(width: 72, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF78909C)), textAlign: TextAlign.right)),
                ]),
                const Divider(height: 10),
                if (invoice.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: Text('No line items', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ...invoice.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Expanded(flex: 4, child: Text(item.description, style: const TextStyle(fontSize: 13))),
                      const SizedBox(width: 8),
                      SizedBox(width: 36, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                      const SizedBox(width: 8),
                      SizedBox(width: 72, child: Text(fmt.format(item.unitPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                      const SizedBox(width: 8),
                      SizedBox(width: 72, child: Text(fmt.format(item.total), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    ]),
                  )),
                const Divider(height: 16),
                _AmountRow(label: 'Subtotal', amount: fmt.format(invoice.subtotal)),
                if (invoice.taxAmount > 0)
                  _AmountRow(label: 'VAT (15%)', amount: fmt.format(invoice.taxAmount)),
                if (invoice.discount > 0)
                  _AmountRow(label: 'Discount', amount: '- ${fmt.format(invoice.discount)}'),
                const Divider(height: 10),
                _AmountRow(
                  label: 'TOTAL DUE',
                  amount: fmt.format(invoice.totalAmount),
                  bold: true,
                  color: AppTheme.darkBlue,
                ),
                if (invoice.amountPaid > 0 && invoice.status != 'paid')
                  _AmountRow(
                    label: 'Balance',
                    amount: fmt.format(invoice.balance),
                    bold: true,
                    color: const Color(0xFFC62828),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (invoice.paymentMethod != null || invoice.medicalAidName != null)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Details',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF546E7A))),
                  const SizedBox(height: 10),
                  if (invoice.paymentMethod != null)
                    InfoRow(
                      label: 'Method',
                      value: _paymentMethodLabel(invoice.paymentMethod!),
                    ),
                  if (invoice.medicalAidName != null)
                    InfoRow(label: 'Medical Aid', value: invoice.medicalAidName!),
                  if (invoice.medicalAidMemberNo != null)
                    InfoRow(label: 'Member No.', value: invoice.medicalAidMemberNo!),
                  if (invoice.medicalAidAuthCode != null)
                    InfoRow(label: 'Auth Code', value: invoice.medicalAidAuthCode!),
                ],
              ),
            ),
          ),
        if (invoice.paymentMethod != null || invoice.medicalAidName != null)
          const SizedBox(height: 12),

        if (invoice.notes != null && invoice.notes!.isNotEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF546E7A))),
                  const SizedBox(height: 8),
                  Text(invoice.notes!, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),

        if (invoice.status != 'paid') ...[
          ElevatedButton.icon(
            onPressed: onMarkPaid,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as Paid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: () => context.go('/billing/${invoice.id}/pay'),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Record Payment'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.darkBlue,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash': return 'Cash';
      case 'card': return 'Card (Yoco)';
      case 'eft': return 'EFT';
      case 'medical_aid': return 'Medical Aid';
      case 'insurance': return 'Insurance';
      default: return method;
    }
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool bold;
  final Color? color;

  const _AmountRow({
    required this.label,
    required this.amount,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 15 : 13,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(amount, style: style),
        ],
      ),
    );
  }
}
