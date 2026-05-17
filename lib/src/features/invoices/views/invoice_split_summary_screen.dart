import 'package:adadi/src/features/invoices/model/invoice_model.dart';
import 'package:flutter/material.dart';

import '../controller/invoice_controller.dart';

class InvoiceSplitSummaryScreen extends StatefulWidget {
  final InvoiceController controller;

  const InvoiceSplitSummaryScreen({super.key, required this.controller});

  @override
  State<InvoiceSplitSummaryScreen> createState() =>
      _InvoiceSplitSummaryScreenState();
}

class _InvoiceSplitSummaryScreenState extends State<InvoiceSplitSummaryScreen> {
  bool _saving = false;

  String _format(double value) => value.toStringAsFixed(2);

  Future<void> _saveInvoice() async {
    setState(() {
      _saving = true;
    });

    try {
      await widget.controller.saveInvoice();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الفاتورة وتحديث القراءات بنجاح')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'تعذر الحفظ النهائي'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.controller.buildInvoiceDetails();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ملخص التقسيم')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: ListTile(
                  title: Text(
                      'نوع الفاتورة: ${widget.controller.invoiceType.arabicLabel}'),
                  subtitle: Text(
                    'إجمالي الفاتورة: ${_format(widget.controller.totalBillAmount)}',
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: details.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = details[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'شقة ${item.unitNumber} - ${item.tenantName.isEmpty ? 'بدون اسم' : item.tenantName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _InfoChip(
                                  label: 'القراءة السابقة',
                                  value: _format(item.previousReading)),
                              _InfoChip(
                                  label: 'القراءة الحالية',
                                  value: _format(item.currentReading)),
                              _InfoChip(
                                  label: 'الاستهلاك',
                                  value: _format(item.consumption)),
                              _InfoChip(
                                  label: 'المبلغ المستحق',
                                  value: _format(item.amountDue)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveInvoice,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('حفظ نهائي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      avatar: const Icon(Icons.analytics_outlined, size: 18),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
