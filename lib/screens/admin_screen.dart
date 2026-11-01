import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/product_model.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('لوحة تحكم المشرف – تعز إكسبرس', style: TextStyle(color: Colors.white, fontSize: 16)),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: 'تسجيل خروج المشرف وإغلاق الجلسة',
                onPressed: () {
                  appState.logoutAdmin();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل خروج المشرف وإغلاق الجلسة بنجاح')));
                },
              ),
            ],
            bottom: const TabBar(
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(icon: Icon(Icons.receipt_long), text: 'الطلبات والتنبيهات'),
                Tab(icon: Icon(Icons.two_wheeler), text: 'المندوبون'),
                Tab(icon: Icon(Icons.inventory_2), text: 'المنتجات وإعداد الدوام'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _OrdersTab(),
              _CouriersTab(),
              _ProductsSettingsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.orders.isEmpty) {
      return const Center(
        child: Text('لا توجد طلبات جديدة حالياً', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: appState.orders.length,
      itemBuilder: (context, index) {
        final order = appState.orders[index];
        final TextEditingController feeController = TextEditingController(text: order['deliveryFee'] > 0 ? order['deliveryFee'].toString() : '');
        String selectedCourier = order['assignedCourier'] != 'لم يتم التعيين' ? order['assignedCourier'] : (appState.couriers.isNotEmpty ? appState.couriers.first['name'] : 'لا يوجد');

        bool isFeeSent = order['isFeeSent'] == true;
        bool isRejected = order['status'] == 'rejectedByCourier';

        return Card(
          color: isRejected ? Colors.red[900] : const Color(0xFF1E1E1E),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('طلب #${order['id']} - العميل: ${order['customerName']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    // 🟢 زر التعديل الجانبي الذي يظهر بعد إرسال الرسوم لتعديلها عند الحاجة
                    if (isFeeSent)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                        tooltip: 'تعديل رسوم التوصيل والمندوب',
                        onPressed: () {
                          appState.enableOrderFeeEditing(order['id']);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم فتح قفل التعديل لرسوم التوصيل')));
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('الهاتف: ${order['phone']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('العنوان: ${order['address']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('المنتجات: ${order['itemsDescription']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('إجمالي المنتجات: ${order['productsTotal']} ر.ي', style: const TextStyle(color: Colors.white70, fontSize: 13)),

                if (order['adminMessage'] != null && order['adminMessage'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Text('📢 ${order['adminMessage']}', style: const TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],

                const Divider(color: Colors.grey),

                // الحقل مقيد إذا تم إرسال الرسوم، وغير مقيد إذا ضغط المشرف على زر التعديل الجانبي
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.phone,
                  enabled: !isFeeSent,
                  style: TextStyle(color: isFeeSent ? Colors.grey : Colors.white),
                  decoration: InputDecoration(
                    labelText: isFeeSent ? 'تم إرسال رسوم التوصيل (مقيد)' : 'حدد رسوم التوصيل (ر.ي)',
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اختر المندوب',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  value: appState.couriers.any((c) => c['name'] == selectedCourier) ? selectedCourier : null,
                  items: appState.couriers.map((courier) {
                    return DropdownMenuItem<String>(
                      value: courier['name'],
                      child: Text('${courier['name']} (${courier['status'] == 'available' ? 'متاح 🟢' : 'مشغول 🔴'})'),
                    );
                  }).toList(),
                  onChanged: isFeeSent ? null : (val) {
                    if (val != null) {
                      selectedCourier = val;
                    }
                  },
                ),
                const SizedBox(height: 10),

                if (!isFeeSent)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 40)),
                    onPressed: () {
                      final fee = double.tryParse(feeController.text) ?? 500.0;
                      appState.setOrderDeliveryFee(order['id'], fee, selectedCourier);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال رسوم التوصيل وقفل الطلب بنجاح!')),
                      );
                    },
                    child: const Text('إرسال رسوم التوصيل وإسناد المندوب للعميل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  )
                else
                  const Center(
                    child: Text('🔒 الطلب مقيد حالياً بانتظار رد العميل (اضغط زر التعديل بالأعلى للتعديل)', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CouriersTab extends StatelessWidget {
  const _CouriersTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text('إضافة مندوب جديد بحساب مستقل', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'اسم المندوب', labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'رقم الهاتف', labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'اسم المستخدم', labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'كلمة السر', labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 40)),
                    onPressed: () {
                      if (nameController.text.isNotEmpty && usernameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                        appState.addCourier(
                          nameController.text,
                          phoneController.text,
                          usernameController.text.trim(),
                          passwordController.text.trim(),
                        );
                        nameController.clear();
                        phoneController.clear();
                        usernameController.clear();
                        passwordController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المندوب بنجاح')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال كافة الحقول')));
                      }
                    },
                    child: const Text('حفظ وإضافة المندوب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: appState.couriers.length,
              itemBuilder: (context, index) {
                final c = appState.couriers[index];
                return ListTile(
                  tileColor: const Color(0xFF1E1E1E),
                  leading: Icon(Icons.circle, color: c['status'] == 'available' ? Colors.green : Colors.red, size: 14),
                  title: Text('المندوب: ${c['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('اسم المستخدم: ${c['username']} | الهاتف: ${c['phone']} | الحالة: ${c['status'] == 'available' ? 'متاح 🟢' : 'مشغول 🔴'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsSettingsTab extends StatefulWidget {
  const _ProductsSettingsTab();

  @override
  State<_ProductsSettingsTab> createState() => _ProductsSettingsTabState();
}

class _ProductsSettingsTabState extends State<_ProductsSettingsTab> {
  late TextEditingController startController;
  late TextEditingController endController;
  final TextEditingController prodNameController = TextEditingController();
  final TextEditingController prodPriceController = TextEditingController();
  String selectedCategory = 'المطاعم';

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    startController = TextEditingController(text: appState.startHour.toString());
    endController = TextEditingController(text: appState.endHour.toString());
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    prodNameController.dispose();
    prodPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('أوقات الدوام الرسمي', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'بداية الدوام', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: endController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'نهاية الدوام', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 40)),
            onPressed: () {
              final s = int.tryParse(startController.text) ?? 11;
              final e = int.tryParse(endController.text) ?? 22;
              appState.setWorkingHours(s, e);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث أوقات الدوام بنجاح')));
            },
            child: const Text('حفظ إعدادات الدوام', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 25),
          const Text('إضافة منتج جديد وتحديد القسم', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            controller: prodNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'اسم المنتج أو الوجبة', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: prodPriceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'السعر (ر.ي)', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'اختر القسم التابع له المنتج',
              labelStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Color(0xFF1E1E1E),
            ),
            value: selectedCategory,
            items: ['المطاعم', 'البقالات', 'الخضار والفواكه', 'الصيدلية الآمنة', 'طلبات أخرى'].map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedCategory = val;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 40)),
            onPressed: () {
              if (prodNameController.text.isNotEmpty && prodPriceController.text.isNotEmpty) {
                appState.addProduct(ProductModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: prodNameController.text,
                  restaurantName: 'متجر الإدارة المعتمد',
                  price: double.tryParse(prodPriceController.text) ?? 1000.0,
                  category: selectedCategory,
                  available: true,
                  imageUrl: '',
                ));
                prodNameController.clear();
                prodPriceController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المنتج بنجاح وتحديثه لدى العميل!')));
              }
            },
            child: const Text('إضافة المنتج للقائمة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 25),
          const Text('المنتجات الحالية', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...(appState.products as List).map((dynamic p) {
            final ProductModel product = p as ProductModel;
            return Card(
              color: const Color(0xFF1E1E1E),
              child: ListTile(
                title: Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${product.restaurantName} - ${product.price} ر.ي (${product.category})', style: const TextStyle(color: Colors.grey)),
                trailing: IconButton(
                  icon: Icon(product.available ? Icons.check_circle : Icons.cancel, color: product.available ? Colors.green : Colors.red),
                  onPressed: () => appState.toggleProductAvailability(product.id),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}