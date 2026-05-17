import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../apartments/model/apartment_model.dart';
import '../model/invoice_model.dart';

class InvoiceController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final TextRecognizer _textRecognizer;

  InvoiceController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final RegExp _meterDigitsRegex = RegExp(r'\d+');

  CameraController? _cameraController;
  bool _scannerReady = false;
  bool _isFrameProcessing = false;
  bool _awaitingValidation = false;

  bool _loading = false;
  String? _error;

  InvoiceType _invoiceType = InvoiceType.electricity;
  double _totalBillAmount = 0;
  final List<ApartmentModel> _apartments = <ApartmentModel>[];
  final Map<String, double> _capturedReadings = <String, double>{};

  String _selectedApartment = '';
  String? _pendingDetectedDigits;

  void Function(String digits)? onDigitsDetected;

  bool get loading => _loading;
  bool get scannerReady => _scannerReady;
  String? get error => _error;
  InvoiceType get invoiceType => _invoiceType;
  double get totalBillAmount => _totalBillAmount;
  CameraController? get cameraController => _cameraController;
  List<ApartmentModel> get apartments => _apartments;
  int get capturedCount => _capturedReadings.length;
  String? get pendingDetectedDigits => _pendingDetectedDigits;

  String get selectedApartment => _selectedApartment;
  bool get isAllApartmentsScanned => _apartments.isEmpty
      ? false
      : _capturedReadings.length >= _apartments.length;

  ApartmentModel? get currentApartment {
    if (isAllApartmentsScanned || _apartments.isEmpty) {
      return null;
    }
    if (_selectedApartment.isEmpty) {
      return _apartments.first;
    }
    return _apartments
        .where((apt) => apt.unitNumber == _selectedApartment)
        .firstOrNull;
  }

  Future<void> setupInvoice({
    required InvoiceType invoiceType,
    required double totalBillAmount,
  }) async {
    _setLoading(true);
    _setError(null);
    _invoiceType = invoiceType;
    _totalBillAmount = totalBillAmount;
    _capturedReadings.clear();
    _selectedApartment = '';
    _pendingDetectedDigits = null;
    _awaitingValidation = false;

    try {
      final snapshot = await _firestore
          .collection('apartments')
          .orderBy('unit_number')
          .get();
      _apartments
        ..clear()
        ..addAll(snapshot.docs.map(
          (doc) => ApartmentModel.fromMap(
            doc.data(),
            doc.id,
          ),
        ));
    } catch (e) {
      _setError('فشل تحميل بيانات الشقق: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeScanner(CameraDescription cameraDescription) async {
    _setError(null);

    if (_cameraController != null) {
      await disposeScanner();
    }

    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await controller.initialize();
      await controller.startImageStream(_processCameraImage);
      _cameraController = controller;
      _scannerReady = true;
      notifyListeners();
    } catch (e) {
      _setError('تعذر تشغيل الكاميرا: $e');
      await controller.dispose();
      rethrow;
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isFrameProcessing || _awaitingValidation || isAllApartmentsScanned) {
      return;
    }

    _isFrameProcessing = true;

    Future.delayed(const Duration(seconds: 1), () {
      _isFrameProcessing = false;
    });

    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) {
        return;
      }

      final recognizedText = await _textRecognizer.processImage(inputImage);
      final digits = _extractDigits(recognizedText.text);
      if (digits == null) {
        return;
      }

      _pendingDetectedDigits = digits;
      _awaitingValidation = true;
      notifyListeners();
      onDigitsDetected?.call(digits);
    } catch (_) {
      log('خطأ أثناء معالجة صورة الكاميرا', error: _);
      // Ignore frame-level OCR errors to keep stream alive.
    } finally {
      _isFrameProcessing = false;
    }
  }

  void rejectPendingReading() {
    _pendingDetectedDigits = null;
    _awaitingValidation = false;
    notifyListeners();
  }

  void confirmPendingReading(String readingText) {
    final apartment = currentApartment;
    if (apartment == null || apartment.id == null) {
      rejectPendingReading();
      return;
    }

    final reading = double.tryParse(readingText);
    if (reading == null) {
      return;
    }

    _capturedReadings[apartment.id!] = reading;
    _pendingDetectedDigits = null;
    _awaitingValidation = false;

    notifyListeners();
  }

  void setManualReadingForCurrentApartment(double reading) {
    final apartment = currentApartment;
    if (apartment == null || apartment.id == null) {
      return;
    }

    _capturedReadings[apartment.id!] = reading;

    notifyListeners();
  }

  List<InvoiceDetail> buildInvoiceDetails() {
    final List<InvoiceDetail> details = <InvoiceDetail>[];

    double totalConsumption = 0;

    for (final apartment in _apartments) {
      final previous = _previousReading(apartment);
      final current = _currentReading(apartment);
      final consumption = math.max(0, current - previous);
      totalConsumption += consumption;
    }

    for (final apartment in _apartments) {
      final previous = _previousReading(apartment);
      final current = _currentReading(apartment);
      final consumption = math.max(0, current - previous);
      final share = totalConsumption <= 0
          ? 0
          : (consumption / totalConsumption) * _totalBillAmount;

      details.add(
        InvoiceDetail(
          unitNumber: apartment.unitNumber,
          tenantName: apartment.tenantName,
          previousReading: previous,
          currentReading: current,
          consumption: consumption.toDouble(),
          amountDue: share.toDouble(),
        ),
      );
    }

    return details;
  }

  Future<void> saveInvoice() async {
    _setLoading(true);
    _setError(null);

    final details = buildInvoiceDetails();
    final invoice = InvoiceModel(
      invoiceDate: Timestamp.now(),
      totalBillAmount: _totalBillAmount,
      invoiceType: _invoiceType.firestoreValue,
      details: details,
    );

    try {
      await _firestore.runTransaction((transaction) async {
        final invoiceRef = _firestore.collection('invoices').doc();
        transaction.set(invoiceRef, invoice.toMap());

        for (final apartment in _apartments) {
          final apartmentId = apartment.id;
          if (apartmentId == null) {
            continue;
          }

          final current = _currentReading(apartment);
          transaction
              .update(_firestore.collection('apartments').doc(apartmentId), {
            _invoiceType.apartmentReadingField: current,
            'last_update': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      _setError('تعذر حفظ الفاتورة: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  double _previousReading(ApartmentModel apartment) {
    return _invoiceType == InvoiceType.electricity
        ? apartment.lastElectricityReading
        : apartment.lastWaterReading;
  }

  double _currentReading(ApartmentModel apartment) {
    final apartmentId = apartment.id;
    if (apartmentId == null) {
      return _previousReading(apartment);
    }
    return _capturedReadings[apartmentId] ?? _previousReading(apartment);
  }

  String? _extractDigits(String rawText) {
    final matches = _meterDigitsRegex
        .allMatches(rawText)
        .map((match) => match.group(0))
        .whereType<String>()
        .toList();

    if (matches.isEmpty) {
      return null;
    }

    matches.sort((a, b) => b.length.compareTo(a.length));
    return matches.first;
  }

  void setSelectedApartment(String apartmentId) {
    _selectedApartment = apartmentId;
  }

  InputImage? _toInputImage(CameraImage image) {
    if (_cameraController == null) {
      return null;
    }

    final rotation = InputImageRotationValue.fromRawValue(
      _cameraController!.description.sensorOrientation,
    );
    if (rotation == null) {
      return null;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      return null;
    }

    final bytes = _mergePlanes(image.planes);
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Uint8List _mergePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  Future<void> disposeScanner() async {
    _scannerReady = false;
    final controller = _cameraController;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
      _cameraController = null;
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeScanner();
    _textRecognizer.close();
    super.dispose();
  }
}
