import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/apartment_model.dart';

class ApartmentController extends ChangeNotifier {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('apartments');

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  Future<void> createApartment(ApartmentModel apartment) async {
    _setLoading(true);
    _setError(null);
    try {
      await _col.add(apartment.toMap());
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<List<ApartmentModel>> getApartments() async {
    _setLoading(true);
    _setError(null);
    try {
      final snap = await _col.orderBy('unit_number').get();
      return snap.docs
          .map((d) =>
              ApartmentModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<ApartmentModel>> getApartmentsStream() {
    return _col.orderBy('unit_number').snapshots().map((snap) => snap.docs
        .map((d) =>
            ApartmentModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  Future<void> updateApartment(String id, ApartmentModel apartment) async {
    _setLoading(true);
    _setError(null);
    try {
      await _col.doc(id).update(apartment.toUpdateMap());
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteApartment(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      await _col.doc(id).delete();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
