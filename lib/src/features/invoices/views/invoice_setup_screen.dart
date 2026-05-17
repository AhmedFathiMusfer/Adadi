import 'package:flutter/material.dart';

import '../controller/invoice_controller.dart';
import '../model/invoice_model.dart';
import 'invoice_batch_scanner_screen.dart';

class InvoiceSetupScreen extends StatefulWidget {
  const InvoiceSetupScreen({super.key});

  @override
  State<InvoiceSetupScreen> createState() => _InvoiceSetupScreenState();
}

class _InvoiceSetupScreenState extends State<InvoiceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final InvoiceController _controller = InvoiceController();

  InvoiceType _selectedType = InvoiceType.electricity;

  @override
  void dispose() {
    _amountController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startScanFlow() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final totalAmount = double.tryParse(_amountController.text.trim());
    if (totalAmount == null || totalAmount <= 0) {
      _showMessage('يرجى إدخال مبلغ صحيح أكبر من صفر');
      return;
    }

    try {
      await _controller.setupInvoice(
        invoiceType: _selectedType,
        totalBillAmount: totalAmount,
      );

      if (!mounted) {
        return;
      }

      if (_controller.apartments.isEmpty) {
        _showMessage('لا توجد شقق مسجلة. أضف الشقق أولاً.');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InvoiceBatchScannerScreen(controller: _controller),
        ),
      );
    } catch (_) {
      _showMessage(_controller.error ?? 'حدث خطأ غير متوقع');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إعداد الفاتورة')),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'نوع الفاتورة',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<InvoiceType>(
                        segments: const [
                          ButtonSegment<InvoiceType>(
                            value: InvoiceType.electricity,
                            label: Text('كهرباء'),
                            icon: Icon(Icons.bolt),
                          ),
                          ButtonSegment<InvoiceType>(
                            value: InvoiceType.water,
                            label: Text('ماء'),
                            icon: Icon(Icons.water_drop),
                          ),
                        ],
                        selected: <InvoiceType>{_selectedType},
                        onSelectionChanged: (value) {
                          setState(() {
                            _selectedType = value.first;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'إجمالي مبلغ الفاتورة',
                          hintText: 'مثال: 1250.75',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long),
                        ),
                        validator: (value) {
                          final amount = double.tryParse((value ?? '').trim());
                          if (amount == null || amount <= 0) {
                            return 'أدخل مبلغًا صحيحًا';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'سيتم توزيع المبلغ تلقائيًا حسب الاستهلاك بعد مسح القراءات لكل الشقق.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _controller.loading ? null : _startScanFlow,
                        icon: _controller.loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt),
                        label: const Text('بدء المسح المتتالي'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
