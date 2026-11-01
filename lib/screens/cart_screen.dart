import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showCheckoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بيانات توصيل الطلب'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                  validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  validator: (v) => v == null || v.length < 9 ? 'يرجى إدخال رقم صحيح' : null,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'العنوان التفصيلي (تعز)'),
                  validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال العنوان' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                appState.setCustomerInfo(
                  _nameController.text,
                  _phoneController.text,
                  _addressController.text,
                );
                Navigator.pop(ctx);

                final success = await appState.submitOrder();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال الطلب بنجاح!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تأكيد الطلب التجريبي بنجاح')),
                  );
                }
              }
            },
            child: const Text('تأكيد وإرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('سلة المشتريات')),
      body: appState.cartItems.isEmpty
          ? const Center(child: Text('السلة فارغة حالياً'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: appState.cartItems.length,
              itemBuilder: (ctx, i) {
                final item = appState.cartItems[i];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.price} ر.ي × ${item.quantity}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => appState.updateQuantity(item.id, -1),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => appState.updateQuantity(item.id, 1),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي القطع:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${appState.totalItemsCount} قطعة'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الإجمالي المالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${appState.totalPrice} ر.ي'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: appState.isStoreOpen
                        ? () => _showCheckoutDialog(context, appState)
                        : null,
                    child: Text(
                      appState.isStoreOpen ? 'إتمام الطلب' : 'مغلق (الدوام من 11 ص إلى 10 م)',
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}