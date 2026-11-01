import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/address_model.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'location_picker_screen.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  String _selectedArea = 'شارع جمال';
  LatLng? _selectedPoint;
  final List<String> _areas = const [
    'شارع جمال',
    'الروضة',
    'المسبح',
    'عصيفرة',
    'الحوبان',
    'بير باشا'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedUser = context.read<AppState>().user;
      if (savedUser != null && mounted) {
        setState(() {
          _nameController.text = savedUser.name;
          _phoneController.text = savedUser.phone;
          _addressController.text = savedUser.defaultAddress?.details ?? '';
          _selectedArea = savedUser.defaultAddress?.area ?? _selectedArea;

          final lat = savedUser.defaultAddress?.latitude;
          final lng = savedUser.defaultAddress?.longitude;
          if (lat != null && lng != null) {
            _selectedPoint = LatLng(lat, lng);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _chooseLocation() async {
    final point = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPoint: _selectedPoint),
      ),
    );
    if (point != null && mounted) {
      setState(() => _selectedPoint = point);
    }
  }

  void _submit() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final double finalLat = _selectedPoint?.latitude ?? 13.58874;
    final double finalLng = _selectedPoint?.longitude ?? 44.01809;

    final address = AddressModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'العنوان الرئيسي',
      area: _selectedArea,
      details: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : 'شارع جمال',
      latitude: finalLat,
      longitude: finalLng,
    );

    try {
      context.read<AppState>().setUser(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: address,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during submit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل بيانات العميل'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'أدخل بياناتك لتحديد موقع التوصيل في تعز',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final required = Validators.requiredText(value, message: 'يرجى إدخال الاسم');
                  if (required != null) return required;
                  if (value!.trim().length < 2) return 'الاسم قصير جداً';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف اليمني',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.yemeniPhone,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedArea,
                decoration: const InputDecoration(
                  labelText: 'المنطقة في تعز',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                items: _areas
                    .map((area) => DropdownMenuItem(value: area, child: Text(area)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedArea = value);
                  }
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'عنوان البيت / المحل التفصيلي',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    Validators.requiredText(value, message: 'يرجى كتابة العنوان التفصيلي'),
              ),
              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: _chooseLocation,
                icon: const Icon(Icons.map_outlined),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: Text(
                  _selectedPoint == null
                      ? 'تحديد الموقع على الخريطة (اختياري)'
                      : 'تم اختيار موقع على الخريطة ✓',
                ),
              ),
              if (_selectedPoint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'الإحداثيات: ${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text(
                    'دخول للتطبيق',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ملاحظة: التسجيل في هذه المرحلة محلي على الجهاز وليس تحققاً عبر SMS أو حساباً سحابياً.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}