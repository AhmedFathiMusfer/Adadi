import 'package:adadi/src/imports/imports.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as Date;
import '../../apartments/controller/apartment_controller.dart';
import '../../apartments/model/apartment_model.dart';
import '../controller/readings_controller.dart';
import 'add_reading_sheet.dart';

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({Key? key}) : super(key: key);

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  final ReadingsController _controller = ReadingsController();
  final ApartmentController _apartmentController = ApartmentController();

  String _selectedType = 'electricity';
  String? _selectedApartmentId;
  DateTime? _selectedMonth;

  void _openAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddReadingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedMonth == null
        ? 'كل الشهور'
        : Date.DateFormat.yMMM('ar').format(_selectedMonth!);

    DateTime? start;
    DateTime? end;
    if (_selectedMonth != null) {
      start = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
      end = DateTime(
          _selectedMonth!.year, _selectedMonth!.month + 1, 0, 23, 59, 59);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('واجهة عرض القراءات'),
          actions: [
            IconButton(onPressed: _openAddSheet, icon: const Icon(Icons.add)),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('كهرباء'),
                      selected: _selectedType == 'electricity',
                      onSelected: (_) =>
                          setState(() => _selectedType = 'electricity'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('ماء'),
                      selected: _selectedType == 'water',
                      onSelected: (_) =>
                          setState(() => _selectedType = 'water'),
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<List<ApartmentModel>>(
                      stream: _apartmentController.getApartmentsStream(),
                      builder: (context, snap) {
                        final apartments = snap.data ?? [];
                        return DropdownButton<String>(
                          value: _selectedApartmentId,
                          hint: const Text('اختر الشقة'),
                          items: [
                            const DropdownMenuItem<String>(
                                value: null, child: Text('الكل'))
                          ]
                              .followedBy(apartments
                                  .map((a) => DropdownMenuItem<String>(
                                        value: a.id,
                                        child: Text(a.unitNumber),
                                      )))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedApartmentId = v),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedMonth ?? now,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            locale: const Locale('ar'),
                            helpText: 'اختر الشهر',
                            selectableDayPredicate: (d) => true,
                          );
                          if (picked != null)
                            setState(() => _selectedMonth =
                                DateTime(picked.year, picked.month));
                        },
                        child: Text(dateLabel)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedMonth = null;
                        _selectedApartmentId = null;
                      }),
                      child: const Text('مسح الفلاتر'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ReadingViewModel>>(
                stream: _controller.streamReadings(
                  utilityType: _selectedType,
                  apartmentId: _selectedApartmentId,
                  startDate: start,
                  endDate: end,
                ),
                builder: (context, snap) {
                  final readings = snap.data ?? [];
                  if (readings.isEmpty) {
                    return const Center(child: Text('لا توجد قراءات'));
                  }
                  return ListView.builder(
                    itemCount: readings.length,
                    itemBuilder: (context, i) {
                      final r = readings[i];
                      final dateStr = Date.DateFormat.yMd('ar')
                          .format(r.readingDate.toDate());
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text('شقة: ${r.apartmentId}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('التاريخ: $dateStr'),
                              Text('القراءة السابقة: ${r.previousReading}'),
                              Text('القراءة الحالية: ${r.currentReading}'),
                              Text('الاستهلاك: ${r.consumption}'),
                            ],
                          ),
                          trailing: Chip(
                            label:
                                Text(r.isCalculated ? 'تمت الحسبة' : 'معلّقة'),
                            backgroundColor: r.isCalculated
                                ? Colors.green[100]
                                : Colors.orange[100],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
