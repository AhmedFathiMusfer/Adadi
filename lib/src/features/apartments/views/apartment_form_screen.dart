import 'package:adadi/src/features/apartments/controller/apartment_controller.dart';
import 'package:adadi/src/features/apartments/model/apartment_model.dart';
import 'package:flutter/material.dart';

class ApartmentFormScreen extends StatefulWidget {
  final ApartmentModel? apartment;
  const ApartmentFormScreen({Key? key, this.apartment}) : super(key: key);
  @override
  State<ApartmentFormScreen> createState() => _ApartmentFormScreenState();
}

class _ApartmentFormScreenState extends State<ApartmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitController = TextEditingController();
  final _tenantController = TextEditingController();
  final _elecController = TextEditingController();
  final _waterController = TextEditingController();
  final ApartmentController _controller = ApartmentController();

  bool get isEdit => widget.apartment != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _unitController.text = widget.apartment!.unitNumber;
      _tenantController.text = widget.apartment!.tenantName;
      _elecController.text =
          widget.apartment!.lastElectricityReading.toString();
      _waterController.text = widget.apartment!.lastWaterReading.toString();
    }
  }

  @override
  void dispose() {
    _unitController.dispose();
    _tenantController.dispose();
    _elecController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  InputDecoration _dec({required String label, required IconData icon}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'تعديل  شقه' : 'إضافة شقه')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                      controller: _unitController,
                      decoration: _dec(label: 'رقم الشقه', icon: Icons.home),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'الرجاء إدخال رقم الشقه'
                          : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _tenantController,
                      decoration:
                          _dec(label: 'اسم المستأجر', icon: Icons.person),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'الرجاء إدخال اسم المستأجر'
                          : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _elecController,
                      decoration: _dec(
                          label: 'قراءة الكهرباء الأخيرة',
                          icon: Icons.flash_on),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'الرجاء إدخال قراءة الكهرباء';
                        return double.tryParse(v) == null
                            ? 'قيمة غير صحيحة'
                            : null;
                      }),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _waterController,
                      decoration:
                          _dec(label: 'قراءة الماء الأخيرة', icon: Icons.water),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'الرجاء إدخال قراءة الماء';
                        return double.tryParse(v) == null
                            ? 'قيمة غير صحيحة'
                            : null;
                      }),
                  const SizedBox(height: 20),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _submit,
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14.0),
                              child: Text(
                                  isEdit ? 'حفظ التغييرات' : 'إضافة الشقه',
                                  style: const TextStyle(fontSize: 16))))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final unit = _unitController.text.trim();
    final tenant = _tenantController.text.trim();
    final elec = double.parse(_elecController.text.trim());
    final water = double.parse(_waterController.text.trim());
    final model = ApartmentModel(
        id: widget.apartment?.id,
        unitNumber: unit,
        tenantName: tenant,
        lastElectricityReading: elec,
        lastWaterReading: water);
    if (isEdit) {
      await _controller.updateApartment(widget.apartment!.id!, model);
      if (_controller.error != null) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_controller.error!)));
        return;
      }
      if (mounted) Navigator.pop(context, true);
    } else {
      await _controller.createApartment(model);
      if (_controller.error != null) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_controller.error!)));
        return;
      }
      if (mounted) Navigator.pop(context, true);
    }
  }
}
