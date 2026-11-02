import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/product_model.dart';
import 'chat_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedNavIndex = 0;

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _restaurantNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  String _selectedCategory = 'المطاعم';

  final TextEditingController _courierNameController = TextEditingController();
  final TextEditingController _courierPhoneController = TextEditingController();
  final TextEditingController _courierUsernameController = TextEditingController();
  final TextEditingController _courierPasswordController = TextEditingController();

  final Map<String, TextEditingController> _feeControllers = {};

  @override
  void dispose() {
    _productNameController.dispose();
    _restaurantNameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _courierNameController.dispose();
    _courierPhoneController.dispose();
    _courierUsernameController.dispose();
    _courierPasswordController.dispose();
    for (var controller in _feeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    final List<Widget> adminPages = [
      _buildOrdersManagement(appState),
      _buildProductsManagement(appState),
      _buildCouriersManagement(appState),
      _buildSettingsTab(appState),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('لوحة تحكم المشرف - تعز إكسبرس', style: TextStyle(color: Colors.white, fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: 'تسجيل خروج المشرف',
              onPressed: () {
                appState.logoutAdmin();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: adminPages[_selectedNavIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (index) => setState(() => _selectedNavIndex = index),
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الطلبات'),
            BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'المنتجات'),
            BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'المناديب'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }

  // 1. إدارة الطلبات وتسعيرها وإسنادها للمندوب
  Widget _buildOrdersManagement(AppState appState) {
    if (appState.orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات جديدة حالياً', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: appState.orders.length,
      itemBuilder: (context, index) {
        final order = appState.orders[index];
        final orderId = order['id'].toString();

        if (!_feeControllers.containsKey(orderId)) {
          _feeControllers[orderId] = TextEditingController(text: order['delivery_fee']?.toString() ?? '0');
        }

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('طلب #$orderId', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('الحالة: ${order['status']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  ],
                ),
                const Divider(color: Colors.grey),
                Text('👤 العميل: ${order['customer_name']} (${order['phone']})', style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text('📍 العنوان: ${order['address']}', style: const TextStyle(color: Colors.white75, fontSize: 13)),
                Text('🛒 المنتجات: ${order['items_description']}', style: const TextStyle(color: Colors.white75, fontSize: 13)),
                Text('💰 سعر المنتجات: ${order['products_total']} ر.ي', style: const TextStyle(color: Colors.white75, fontSize: 13)),
                const SizedBox(height: 10),

                // حقل إدخال رسوم التوصيل واختيار المندوب
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _feeControllers[orderId],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'رسوم التوصيل (ر.ي)',
                          labelStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Color(0xFF121212),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'اختر المندوب',
                          labelStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Color(0xFF121212),
                          border: OutlineInputBorder(),
                        ),
                        value: appState.couriers.any((c) => c['name'] == order['assigned_courier'])
                            ? order['assigned_courier']
                            : null,
                        items: appState.couriers.map<DropdownMenuItem<String>>((courier) {
                          return DropdownMenuItem<String>(
                            value: courier['name'].toString(),
                            child: Text(courier['name'].toString(), style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            order['assigned_courier'] = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () {
                    final fee = double.tryParse(_feeControllers[orderId]?.text ?? '0') ?? 0.0;
                    final courierName = order['assigned_courier'] ?? 'لم يتم التعيين';
                    if (courierName == 'لم يتم التعيين') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الرجاء اختيار مندوب أولاً')),
                      );
                      return;
                    }
                    appState.setOrderDeliveryFee(orderId, fee, courierName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديد الرسوم وإسناد الطلب بنجاح! ✅')),
                    );
                  },
                  child: const Text('إرسال التسعيرة للعميل وإسناد الطلب للمندوب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.chat, color: Colors.amber),
                      label: const Text('مراسلة العميل', style: TextStyle(color: Colors.amber)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              orderId: orderId,
                              userRole: 'admin',
                              targetChat: 'admin_customer',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. إدارة المنتجات وإضافتها
  Widget _buildProductsManagement(AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('إضافة منتج جديد للمتجر', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: _productNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'اسم المنتج', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _restaurantNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'اسم المتجر أو المطعم', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'السعر (ر.ي)', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'القسم', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
            items: ['المطاعم', 'البقالات', 'الخضار والفواكه', 'الصيدلية الآمنة'].map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (_productNameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
                final newProduct = ProductModel(
                  id: 'P-${DateTime.now().millisecondsSinceEpoch}',
                  name: _productNameController.text,
                  restaurantName: _restaurantNameController.text.isEmpty ? 'متجر عام' : _restaurantNameController.text,
                  price: double.tryParse(_priceController.text) ?? 0.0,
                  category: _selectedCategory,
                  available: true,
                  imageUrl: '',
                );
                appState.addProduct(newProduct);
                _productNameController.clear();
                _restaurantNameController.clear();
                _priceController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المنتج بنجاح! ✅')));
              }
            },
            child: const Text('حفظ وإضافة المنتج', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 3. إدارة المناديب وإضافتهم
  Widget _buildCouriersManagement(AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('إضافة مندوب توصيل جديد', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: _courierNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'اسم المندوب الكامل', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _courierPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'رقم الهاتف', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _courierUsernameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'اسم المستخدم للدخول', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _courierPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'كلمة المرور', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (_courierNameController.text.isNotEmpty && _courierUsernameController.text.isNotEmpty) {
                appState.addCourier(
                  _courierNameController.text,
                  _courierPhoneController.text,
                  _courierUsernameController.text,
                  _courierPasswordController.text,
                );
                _courierNameController.clear();
                _courierPhoneController.clear();
                _courierUsernameController.clear();
                _courierPasswordController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المندوب بنجاح! 🛵')));
              }
            },
            child: const Text('حفظ المندوب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 4. إعدادات المتجر وأوقات الدوام (المصححة لتعمل بسلاسة مع Supabase)
  Widget _buildSettingsTab(AppState appState) {
    final startController = TextEditingController(text: appState.startHour.toString());
    final endController = TextEditingController(text: appState.endHour.toString());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إعدادات أوقات الدوام الرسمي للمتجر', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: startController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'ساعة الفتح (مثال: 8)', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: endController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'ساعة الإغلاق (مثال: 24)', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 45)),
            onPressed: () {
              final start = int.tryParse(startController.text) ?? 8;
              final end = int.tryParse(endController.text) ?? 24;
              
              // 👈 التعديل هنا: استخدام دالة التحديث السحابي الصحيحة
              appState.updateStoreSettings(start, end);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث أوقات الدوام وحفظها سحابياً للطرفين بنجاح! ✅')),
              );
            },
            child: const Text('حفظ وتحديث أوقات الدوام', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
