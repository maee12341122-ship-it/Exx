import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'delivery_dashboard.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});

  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    final courier = context.read<AppState>().courierByPhone(_phoneController.text);
    if (courier == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد مندوب مفعّل بهذا الرقم على هذا الجهاز.')));
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DeliveryDashboard(deliveryId: courier.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول المندوب')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delivery_dining, size: 76, color: AppConstants.gold),
              const SizedBox(height: 16),
              const Text('أدخل رقم الهاتف المسجل للمندوب', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف اليمني', prefixIcon: Icon(Icons.phone)),
                validator: Validators.yemeniPhone,
              ),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _login, child: const Text('دخول حساب المندوب'))),
              const SizedBox(height: 14),
              const Text(
                'تنبيه: هذا تحقق محلي بالرقم فقط لأغراض الاختبار، وليس مصادقة آمنة. يجب ربط حسابات المندوبين بخادم قبل الإطلاق.',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 11, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
