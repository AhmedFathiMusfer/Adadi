import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controller/invoice_controller.dart';
import 'invoice_split_summary_screen.dart';

class InvoiceBatchScannerScreen extends StatefulWidget {
  final InvoiceController controller;

  const InvoiceBatchScannerScreen({super.key, required this.controller});

  @override
  State<InvoiceBatchScannerScreen> createState() =>
      _InvoiceBatchScannerScreenState();
}

class _InvoiceBatchScannerScreenState extends State<InvoiceBatchScannerScreen> {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.onDigitsDetected = _onDigitsDetected;
    _initCamera();
  }

  @override
  void dispose() {
    widget.controller.onDigitsDetected = null;
    widget.controller.disposeScanner();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showMessage('لم يتم العثور على كاميرا في الجهاز');
        return;
      }

      final camera = cameras.firstWhere(
        (description) => description.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      await widget.controller.initializeScanner(camera);
    } catch (_) {
      _showMessage(widget.controller.error ?? 'تعذر تهيئة الكاميرا');
    }
  }

  Future<void> _onDigitsDetected(String digits) async {
    if (!mounted || _dialogOpen) {
      return;
    }

    _dialogOpen = true;
    final manualController = TextEditingController(text: digits);

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد القراءة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('هل القراءة $digits صحيحة؟'),
                const SizedBox(height: 12),
                TextField(
                  controller: manualController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'يمكنك التعديل عند الحاجة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownMenu<String>(
                  label: const Text('اختر الشقة '),
                  hintText: 'اختر الشقة التي تم مسح عدادها',
                  initialSelection: widget.controller.selectedApartment.isEmpty
                      ? null
                      : widget.controller.selectedApartment,
                  dropdownMenuEntries: widget.controller.apartments
                      .map((apt) => DropdownMenuEntry(
                          value: apt.unitNumber,
                          label:
                              'شقة ${apt.tenantName.isEmpty ? 'بدون اسم' : apt.tenantName} - ${apt.unitNumber}'))
                      .toList(),
                  onSelected: (unit) {
                    widget.controller.setSelectedApartment(unit ?? '');
                  },
                ),
                const SizedBox(
                  height: 8,
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('retry'),
                child: const Text('إعادة المسح'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('edit'),
                child: const Text('تعديل'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop('confirm'),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case 'confirm':
        widget.controller.confirmPendingReading(digits);
        break;
      case 'edit':
        widget.controller.confirmPendingReading(manualController.text.trim());
        break;
      default:
        widget.controller.rejectPendingReading();
    }

    manualController.dispose();
    _dialogOpen = false;

    if (widget.controller.isAllApartmentsScanned && mounted) {
      _showMessage('اكتمل مسح جميع الشقق. انتقل إلى الملخص للحفظ النهائي.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSummary() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            InvoiceSplitSummaryScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final apartment = widget.controller.currentApartment;
            final cameraController = widget.controller.cameraController;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (widget.controller.scannerReady &&
                    cameraController != null &&
                    cameraController.value.isInitialized)
                  CameraPreview(cameraController)
                else
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: _TopBanner(
                    text: apartment == null
                        ? 'تم مسح جميع الشقق'
                        : 'الآن: مسح عداد شقة ${apartment.unitNumber}',
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: IgnorePointer(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.72,
                      height: MediaQuery.of(context).size.height * 0.22,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: Card(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'تم مسح ${widget.controller.capturedCount} من ${widget.controller.apartments.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: widget.controller.isAllApartmentsScanned
                                ? _openSummary
                                : null,
                            icon: const Icon(Icons.table_chart),
                            label: const Text('الانتقال إلى ملخص التقسيم'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBanner extends StatelessWidget {
  final String text;

  const _TopBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
