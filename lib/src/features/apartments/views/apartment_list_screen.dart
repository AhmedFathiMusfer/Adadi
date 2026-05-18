import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../controller/apartment_controller.dart';
import '../model/apartment_model.dart';
import 'apartment_form_screen.dart';

class ApartmentListScreen extends StatefulWidget {
  const ApartmentListScreen({super.key});

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
        padding: const EdgeInsets.all(12),
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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final a = apartments[index];
                return Card(
                  elevation: 4,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    style: ListTileStyle.list,
                    splashColor: Colors.blueGrey.withValues(alpha: 0.1),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CircleAvatar(
                        radius: 30,
                        child: Text(a.unitNumber,
                            style: const TextStyle(color: Colors.white))),
                    title: Text(
                        a.tenantName.isNotEmpty ? a.tenantName : a.unitNumber,
                        style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text(
                        a.lastUpdate != null
                            ? DateFormat.yMMMd('ar')
                                .add_Hm()
                                .format(a.lastUpdate!)
                            : '---',
                        style: Theme.of(context).textTheme.bodySmall),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push<bool?>(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ApartmentFormScreen(apartment: a)));
                        } else if (value == 'delete') {
                          _confirmDelete(context, a);
                        }
                      },
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('تعديل'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف'),
                          ),
                        ];
                      },
                    ),
                    onTap: () async {
                      final updated = await Navigator.push<bool?>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ApartmentFormScreen(apartment: a)));
                      if (updated ?? false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم التحديث')));
                      }
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
          if ((created ?? false) && mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('تم الإضافة')));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ApartmentModel apartment) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('حذف الشقه', style: Theme.of(context).textTheme.titleMedium),
        content: Text('هل أنت متأكد من حذف الشقه ${apartment.unitNumber} ؟',
            style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if ((res ?? false) && mounted) {
      await _controller.deleteApartment(apartment.id!);
      if (_controller.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_controller.error!)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحذف')));
      }
    }
  }
}
