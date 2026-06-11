import 'package:cloud_firestore/cloud_firestore.dart';

class ElectricityReadingModel {
  final String id;
  final String apartmentId;
  final double previousReading;
  final double currentReading;
  final double consumption;
  final Timestamp readingDate;
  final bool isCalculated;

  ElectricityReadingModel({
    required this.id,
    required this.apartmentId,
    required this.previousReading,
    required this.currentReading,
    required this.consumption,
    required this.readingDate,
    this.isCalculated = false,
  });

  factory ElectricityReadingModel.fromMap(Map<String, dynamic> map, String id) {
    return ElectricityReadingModel(
      id: id,
      apartmentId: map['apartment_id'] ?? '',
      previousReading: (map['previous_reading'] ?? 0).toDouble(),
      currentReading: (map['current_reading'] ?? 0).toDouble(),
      consumption: (map['consumption'] ?? 0).toDouble(),
      readingDate: map['reading_date'] is Timestamp
          ? map['reading_date'] as Timestamp
          : Timestamp.now(),
      isCalculated: map['is_calculated'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'apartment_id': apartmentId,
      'previous_reading': previousReading,
      'current_reading': currentReading,
      'consumption': consumption,
      'reading_date': readingDate,
      'is_calculated': isCalculated,
    };
  }
}
