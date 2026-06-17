import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:medcenter/modules/billing/billing_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/billing_model.dart';
import 'package:medcenter/shared/utils/date_formatter.dart';
import 'package:medcenter/shared/widgets/empty_state.dart';

class BillingListScreen extends StatefulWidget {
  const BillingListScreen({super.key});

  @override
  State<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends State<BillingListScreen> {
  List<InvoiceModel> _invoices = [];
  bool _loading = true;
  String _filter = 'all'; // all | unpaid | paid | overdue

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await BillingRepository.instance.listInvoices();
      if (mounted) setState(() { _invoices = all; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<InvoiceModel> get _filtered {
    if (_filter == 'all') return _invoices;
    return _invoices.where((i) => i.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_ZA', symbol: 'R ');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Billing & Invoices'),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: ['all', 'unpaid', 'partial', 'paid', 'overdue'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f[0].toUpperCase() + f.substring(1),
                        style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white : Colors.white70)),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    selectedColor: Colors.white.withValues(alpha: 0.3),
                    checkmarkColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? 
      EmptyState(
  icon: Icons.receipt_long_outlined,
  message: _filter == 'all'
      ? 'No invoices — invoices will appear here once created'
      : 'No $_filter invoices',
)

      
      : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final inv = _filtered[i];
                      return _InvoiceCard(
                        invoice: inv,
                        fmt: fmt,
                        onTap: () => context.go('/billing/${inv.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.fmt, required this.onTap});

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
    final color = _statusColor(invoice.status);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(invoice.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (invoice.patientName != null)
                  Text(invoice.patientName!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF546E7A))),
                Text(DateFormatter.format(invoice.date),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmt.format(invoice.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  invoice.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
