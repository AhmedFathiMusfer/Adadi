import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility invoice type used by setup and persistence layers.
enum InvoiceType { electricity, water }

extension InvoiceTypeX on InvoiceType {
  String get firestoreValue {
    switch (this) {
      case InvoiceType.electricity:
        return 'Electricity';
      case InvoiceType.water:
        return 'Water';
    }
  }

  String get arabicLabel {
    switch (this) {
      case InvoiceType.electricity:
        return 'كهرباء';
      case InvoiceType.water:
        return 'ماء';
    }
  }

  String get apartmentReadingField {
    switch (this) {
      case InvoiceType.electricity:
        return 'last_electricity_reading';
      case InvoiceType.water:
        return 'last_water_reading';
    }
  }

  static InvoiceType fromFirestoreValue(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'water') {
      return InvoiceType.water;
    }
    return InvoiceType.electricity;
  }
}

class InvoiceDetail {
  final String unitNumber;
  final String tenantName;
  final double previousReading;
  final double currentReading;
  final double consumption;
  final double amountDue;

  const InvoiceDetail({
    required this.unitNumber,
    required this.tenantName,
    required this.previousReading,
    required this.currentReading,
    required this.consumption,
    required this.amountDue,
  });

  factory InvoiceDetail.fromMap(Map<String, dynamic> map) {
    return InvoiceDetail(
      unitNumber: (map['unit_number'] ?? '').toString(),
      tenantName: (map['tenant_name'] ?? '').toString(),
      previousReading: _toDouble(map['previous_reading']),
      currentReading: _toDouble(map['current_reading']),
      consumption: _toDouble(map['consumption']),
      amountDue: _toDouble(map['amount_due']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'unit_number': unitNumber,
      'tenant_name': tenantName,
      'previous_reading': previousReading,
      'current_reading': currentReading,
      'consumption': consumption,
      'amount_due': amountDue,
    };
  }
}

class InvoiceModel {
  final String? id;
  final Timestamp invoiceDate;
  final double totalBillAmount;
  final String invoiceType;
  final List<InvoiceDetail> details;

  const InvoiceModel({
    this.id,
    required this.invoiceDate,
    required this.totalBillAmount,
    required this.invoiceType,
    required this.details,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    final rawDetails = (map['details'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    return InvoiceModel(
      id: id,
      invoiceDate: map['invoice_date'] is Timestamp
          ? map['invoice_date'] as Timestamp
          : Timestamp.now(),
      totalBillAmount: InvoiceDetail._toDouble(map['total_bill_amount']),
      invoiceType: (map['invoice_type'] ?? 'Electricity').toString(),
      details: rawDetails.map(InvoiceDetail.fromMap).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoice_date': invoiceDate,
      'total_bill_amount': totalBillAmount,
      'invoice_type': invoiceType,
      'details': details.map((detail) => detail.toMap()).toList(),
    };
  }
}
