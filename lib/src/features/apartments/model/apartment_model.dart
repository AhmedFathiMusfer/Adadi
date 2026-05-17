import 'package:cloud_firestore/cloud_firestore.dart';

/// Apartment model representing a unit in the building.
class ApartmentModel {
  final String? id;
  final String unitNumber;
  final String tenantName;
  final double lastElectricityReading;
  final double lastWaterReading;
  final DateTime? lastUpdate;

  ApartmentModel({
    this.id,
    required this.unitNumber,
    required this.tenantName,
    required this.lastElectricityReading,
    required this.lastWaterReading,
    this.lastUpdate,
  });

  factory ApartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return ApartmentModel(
      id: id,
      unitNumber: map['unit_number'] ?? '',
      tenantName: map['tenant_name'] ?? '',
      lastElectricityReading: (map['last_electricity_reading'] ?? 0).toDouble(),
      lastWaterReading: (map['last_water_reading'] ?? 0).toDouble(),
      lastUpdate: map['last_update'] is Timestamp
          ? (map['last_update'] as Timestamp).toDate()
          : map['last_update'] is DateTime
              ? (map['last_update'] as DateTime)
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'unit_number': unitNumber,
      'tenant_name': tenantName,
      'last_electricity_reading': lastElectricityReading,
      'last_water_reading': lastWaterReading,
      'last_update': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() => toMap();
}
