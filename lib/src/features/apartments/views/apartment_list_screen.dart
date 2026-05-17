import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../controller/apartment_controller.dart';
import '../model/apartment_model.dart';
import 'apartment_form_screen.dart';

class ApartmentListScreen extends StatefulWidget {
  const ApartmentListScreen({Key? key}) : super(key: key);

  @override
  State<ApartmentListScreen> createState() => _ApartmentListScreenState();
}

class _ApartmentListScreenState extends State<ApartmentListScreen> {
  final ApartmentController _controller = ApartmentController();
  final _currency = NumberFormat('#,##0.##');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشقق')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<List<ApartmentModel>>(
          stream: _controller.getApartmentsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final apartments = snapshot.data ?? [];
            if (apartments.isEmpty) {
              return Center(
                  child: Text('لا توجد شقق مسجلة بعد',
                      style: Theme.of(context).textTheme.bodyLarge));
            }
            return ListView.separated(
              itemCount: apartments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final a = apartments[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    title: Text('الوحدة ${a.unitNumber}',
                        style: Theme.of(context).textTheme.titleMedium),
                    subtitle:
                        Text(a.tenantName.isNotEmpty ? a.tenantName : 'فارغ'),
                    trailing: SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              'كهرباء: ${_currency.format(a.lastElectricityReading)}'),
                          const SizedBox(height: 6),
                          Text('ماء: ${_currency.format(a.lastWaterReading)}'),
                          const SizedBox(height: 6),
                          Text(
                              a.lastUpdate != null
                                  ? DateFormat.yMMMd('ar')
                                      .add_Hm()
                                      .format(a.lastUpdate!)
                                  : '---',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    onTap: () async {
                      final updated = await Navigator.push<bool?>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ApartmentFormScreen(apartment: a)));
                      if (updated == true)
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم التحديث')));
                    },
                    onLongPress: () => _confirmDelete(context, a),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool?>(context,
              MaterialPageRoute(builder: (_) => const ApartmentFormScreen()));
          if (created == true)
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('تم الإضافة')));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ApartmentModel apartment) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الوحدة'),
        content: Text('هل أنت متأكد من حذف الوحدة ${apartment.unitNumber} ؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (res == true) {
      await _controller.deleteApartment(apartment.id!);
      if (_controller.error != null)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_controller.error!)));
      else
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحذف')));
    }
  }
}
