import 'package:cloud_firestore/cloud_firestore.dart';
import '../../apartments/controller/apartment_controller.dart';

class ReadingViewModel {
  final String id;
  final String apartmentId;
  final double previousReading;
  final double currentReading;
  final double consumption;
  final Timestamp readingDate;
  final bool isCalculated;
  final String utilityType; // 'electricity' or 'water'

  ReadingViewModel({
    required this.id,
    required this.apartmentId,
    required this.previousReading,
    required this.currentReading,
    required this.consumption,
    required this.readingDate,
    required this.isCalculated,
    required this.utilityType,
  });
}

class ReadingsController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ApartmentController _apartmentController = ApartmentController();

  String _collectionFor(String type) {
    return type.toLowerCase() == 'water'
        ? 'water_readings'
        : 'electricity_readings';
  }

  Stream<List<ReadingViewModel>> streamReadings({
    required String utilityType,
    String? apartmentId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query col = _db
        .collection(_collectionFor(utilityType))
        .orderBy('reading_date', descending: true);

    if (apartmentId != null && apartmentId.isNotEmpty) {
      col = col.where('apartment_id', isEqualTo: apartmentId);
    }

    if (startDate != null) {
      col = col.where('reading_date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      col = col.where('reading_date',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return col.snapshots().map((snap) {
      return snap.docs.map((d) {
        final map = d.data() as Map<String, dynamic>;
        return ReadingViewModel(
          id: d.id,
          apartmentId: map['apartment_id'] ?? '',
          previousReading: (map['previous_reading'] ?? 0).toDouble(),
          currentReading: (map['current_reading'] ?? 0).toDouble(),
          consumption: (map['consumption'] ?? 0).toDouble(),
          readingDate: map['reading_date'] is Timestamp
              ? map['reading_date'] as Timestamp
              : Timestamp.now(),
          isCalculated: map['is_calculated'] ?? false,
          utilityType: utilityType,
        );
      }).toList();
    });
  }

  Future<void> addNewReading({
    required String apartmentId,
    required double currentReading,
    required String type, // 'electricity' or 'water'
  }) async {
    final String colName = _collectionFor(type);
    final DocumentReference apartmentRef =
        _db.collection('apartments').doc(apartmentId);
    final CollectionReference readingsCol = _db.collection(colName);

    await _db.runTransaction((tx) async {
      final aptSnap = await tx.get(apartmentRef);
      if (!aptSnap.exists) throw Exception('Apartment not found');

      final aptData = aptSnap.data() as Map<String, dynamic>;
      double previous = 0.0;
      if (type.toLowerCase() == 'water') {
        previous = (aptData['last_water_reading'] ?? 0).toDouble();
      } else {
        previous = (aptData['last_electricity_reading'] ?? 0).toDouble();
      }

      final double consumption = currentReading - previous;

      final newDocRef = readingsCol.doc();
      final now = Timestamp.now();

      final readingMap = {
        'apartment_id': apartmentId,
        'previous_reading': previous,
        'current_reading': currentReading,
        'consumption': consumption,
        'reading_date': now,
        'is_calculated': true,
      };

      tx.set(newDocRef, readingMap);

      // update apartment last reading field
      final updateMap = <String, dynamic>{};
      if (type.toLowerCase() == 'water') {
        updateMap['last_water_reading'] = currentReading;
      } else {
        updateMap['last_electricity_reading'] = currentReading;
      }
      updateMap['last_update'] = FieldValue.serverTimestamp();

      tx.update(apartmentRef, updateMap);
    });
  }
}
