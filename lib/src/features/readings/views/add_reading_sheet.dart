import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../apartments/controller/apartment_controller.dart';
import '../../apartments/model/apartment_model.dart';
import '../controller/readings_controller.dart';

class AddReadingSheet extends StatefulWidget {
  const AddReadingSheet({Key? key}) : super(key: key);

  @override
  State<AddReadingSheet> createState() => _AddReadingSheetState();
}

class _AddReadingSheetState extends State<AddReadingSheet> {
  final ApartmentController _apartmentController = ApartmentController();
  final ReadingsController _readingsController = ReadingsController();
  String _type = 'electricity';
  String? _selectedApartmentId;
  ApartmentModel? _selectedApartment;
  final TextEditingController _currentController = TextEditingController();
  double _consumption = 0.0;

  void _onApartmentChanged(String? id, List<ApartmentModel> apartments) {
    setState(() {
      _selectedApartmentId = id;
      _selectedApartment = apartments.firstWhere((a) => a.id == id,
          orElse: () => ApartmentModel(
              id: null,
              unitNumber: '',
              tenantName: '',
              lastElectricityReading: 0.0,
              lastWaterReading: 0.0));
      _updateConsumption();
    });
  }

  void _updateConsumption() {
    final prev = _type == 'water'
        ? (_selectedApartment?.lastWaterReading ?? 0)
        : (_selectedApartment?.lastElectricityReading ?? 0);
    final cur = double.tryParse(_currentController.text) ?? 0.0;
    setState(() => _consumption = cur - prev);
  }

  Future<void> _save() async {
    if (_selectedApartmentId == null) return;
    final cur = double.tryParse(_currentController.text);
    if (cur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال قراءة صحيحة')));
      return;
    }

    try {
      await _readingsController.addNewReading(
          apartmentId: _selectedApartmentId!, currentReading: cur, type: _type);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: ChoiceChip(
                      label: const Text('كهرباء'),
                      selected: _type == 'electricity',
                      onSelected: (_) => setState(() {
                        _type = 'electricity';
                        _updateConsumption();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ChoiceChip(
                      label: const Text('ماء'),
                      selected: _type == 'water',
                      onSelected: (_) => setState(() {
                        _type = 'water';
                        _updateConsumption();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<ApartmentModel>>(
                stream: _apartmentController.getApartmentsStream(),
                builder: (context, snap) {
                  final apartments = snap.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedApartmentId,
                    hint: const Text('اختر الشقة'),
                    items: apartments
                        .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.unitNumber} - ${a.tenantName}')))
                        .toList(),
                    onChanged: (v) => _onApartmentChanged(v, apartments),
                    validator: (v) => v == null ? 'الرجاء اختيار الشقة' : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                      'القراءة السابقة تلقائياً: ${_type == 'water' ? _selectedApartment?.lastWaterReading ?? 0 : _selectedApartment?.lastElectricityReading ?? 0}')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'القراءة الحالية'),
                onChanged: (_) => _updateConsumption(),
              ),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                      'الاستهلاك الحالي: ${_consumption.toStringAsFixed(2)} ${_type == 'water' ? 'متر مكعب' : 'كيلوواط'}')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('حفظ القراءة'),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
