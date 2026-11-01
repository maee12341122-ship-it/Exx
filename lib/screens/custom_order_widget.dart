import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class CustomOrderWidget extends StatefulWidget {
  const CustomOrderWidget({super.key});

  @override
  State<CustomOrderWidget> createState() => _CustomOrderWidgetState();
}

class _CustomOrderWidgetState extends State<CustomOrderWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppState>().addCustomItem(
          name: _nameController.text,
          price: int.parse(_priceController.text),
          quantity: int.parse(_quantityController.text),
          notes: _notesController.text,
        );
    _nameController.clear();
    _priceController.clear();
    _quantityController.text = '1';
    _notesController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أُضيف الطلب الخاص إلى السلة')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('طلبات أخرى', style: TextStyle(color: AppConstants.gold, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('اكتب الغرض المطلوب وسعره التقديري. سيحتاج السعر إلى مراجعة الإدارة قبل اعتماده.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم المنتج المطلوب'),
              validator: (value) => Validators.requiredText(value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'السعر التقديري بالريال اليمني'),
              validator: (value) {
                if (value == null || int.tryParse(value) == null || int.parse(value) < 0) return 'أدخل سعراً صحيحاً';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية'),
              validator: (value) {
                if (value == null || int.tryParse(value) == null || int.parse(value) < 1) return 'أدخل كمية صحيحة';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'الوصف أو الملاحظات (اختياري)'),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add_shopping_cart), label: const Text('إضافة الطلب إلى السلة')),
          ],
        ),
      ),
    );
  }
}
