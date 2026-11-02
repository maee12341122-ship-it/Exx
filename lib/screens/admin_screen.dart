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

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _pNameController = TextEditingController();
  final TextEditingController _pPriceController = TextEditingController();
  final TextEditingController _pRestaurantController = TextEditingController();
  String _pCategory = 'المطاعم';

  final TextEditingController _cNameController = TextEditingController();
  final TextEditingController _cPhoneController = TextEditingController();
  final TextEditingController _cUserCtrl = TextEditingController();
  final TextEditingController _cPassCtrl = TextEditingController();

  final TextEditingController _startHourController = TextEditingController();
  final TextEditingController _endHourController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pNameController.dispose();
    _pPriceController.dispose();
    _pRestaurantController.dispose();
    _cNameController.dispose();
    _cPhoneController.dispose();
    _cUserCtrl.dispose();
    _cPassCtrl.dispose();
    _startHourController.dispose();
    _endHourController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('لوحة تحكم المشرف العامة', style: TextStyle(color: Colors.white, fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                appState.logoutAdmin();
                Navigator.pop(context);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.amber,
            tabs: const [
              Tab(text: 'الطلبات الواردة'),
              Tab(text: 'إدارة المنتجات والدوام'),
              Tab(text: 'إدارة المناديب'),
              Tab(text: 'التنبيهات الإدارية'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersTab(appState),
            _buildProductsAndHoursTab(appState),
            _buildCouriersTab(appState),
            _buildNotificationsTab(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(AppState appState) {
    if (appState.orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات جديدة حالياً', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: appState.orders.length,
      itemBuilder: (context, index) {
        final order = appState.orders[index];
        final orderId = order['id'].toString();
        final feeController = TextEditingController(text: (order['delivery_fee'] ?? 500).toString());

        // جلب اسم المندوب المعين إن وُجد
        String assignedCourierName = order['assigned_courier'] ?? 'لم يتم التعيين';
        String selectedCourier = appState.couriers.any((c) => c['name'] == assignedCourierName)
            ? assignedCourierName
            : (appState.couriers.isNotEmpty ? appState.couriers[0]['name'] : '');

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('طلب #$orderId', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_bubble, color: Colors.amber),
                          tooltip: 'مراسلة العميل',
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
                        IconButton(
                          icon: const Icon(Icons.two_wheeler, color: Colors.cyanAccent),
                          tooltip: 'مراسلة المندوب',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  orderId: orderId,
                                  userRole: 'admin',
                                  targetChat: 'admin_courier',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('العميل: ${order['customer_name'] ?? ''} | هاتف: ${order['phone'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('العنوان: ${order['address'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('الطلبات: ${order['items_description'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('سعر المنتجات: ${order['products_total'] ?? 0} ر.ي', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('الحالة: ${order['status'] ?? ''}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                const Divider(color: Colors.grey),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: feeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'رسوم التوصيل', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: appState.couriers.any((c) => c['name'] == selectedCourier) ? selectedCourier : null,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        items: appState.couriers.map<DropdownMenuItem<String>>((c) {
                          return DropdownMenuItem<String>(
                            value: c['name'],
                            child: Text(c['name'], style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) selectedCourier = val;
                        },
                        decoration: const InputDecoration(labelText: 'اختر المندوب', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 38)),
                  onPressed: () {
                    double fee = double.tryParse(feeController.text) ?? 500.0;
                    appState.setOrderDeliveryFee(orderId, fee, selectedCourier);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث وإرسال التسعيرة والمندوب بنجاح!')));
                  },
                  child: const Text('تحديث وإرسال للمندوب والعميل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 5),
                Text('ملاحظة: ${order['admin_message'] ?? ''}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsAndHoursTab(AppState appState) {
    if (_startHourController.text.isEmpty) {
      _startHourController.text = appState.startHour.toString();
      _endHourController.text = appState.endHour.toString();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⏰ التحكم بساعات الدوام الرسمي للعمل', style: TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startHourController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'ساعة الفتح', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: _endHourController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'ساعة الإغلاق', labelStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 38)),
                  onPressed: () {
                    int start = int.tryParse(_startHourController.text) ?? 11;
                    int end = int.tryParse(_endHourController.text) ?? 22;
                    appState.setWorkingHours(start, end);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث ساعات الدوام بنجاح! ✅')));
                  },
                  child: const Text('حفظ وتحديث ساعات الدوام', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey, height: 30),
          const Text('إضافة منتج أو صنف جديد', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _pNameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'اسم المنتج', labelStyle: TextStyle(color: Colors.grey))),
          TextField(controller: _pPriceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'السعر (ر.ي)', labelStyle: TextStyle(color: Colors.grey))),
          TextField(controller: _pRestaurantController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'اسم المتجر / المطعم', labelStyle: TextStyle(color: Colors.grey))),
          DropdownButton<String>(
            value: _pCategory,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            items: ['المطاعم', 'البقالات', 'الخضار والفواكه', 'الصيدلية الآمنة', 'طلبات أخرى'].map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (val) => setState(() => _pCategory = val!),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (_pNameController.text.isNotEmpty && _pPriceController.text.isNotEmpty) {
                appState.addProduct(ProductModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _pNameController.text,
                  restaurantName: _pRestaurantController.text.isEmpty ? 'متجر عام' : _pRestaurantController.text,
                  price: double.tryParse(_pPriceController.text) ?? 1000.0,
                  category: _pCategory,
                  available: true,
                  imageUrl: '',
                ));
                _pNameController.clear();
                _pPriceController.clear();
                _pRestaurantController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المنتج بنجاح!')));
              }
            },
            child: const Text('حفظ وإضافة المنتج', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCouriersTab(AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('إضافة مندوب توصيل جديد', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _cNameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'اسم المندوب الكامل', labelStyle: TextStyle(color: Colors.grey))),
          TextField(controller: _cPhoneController, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'رقم الهاتف', labelStyle: TextStyle(color: Colors.grey))),
          TextField(controller: _cUserCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'اسم المستخدم للدخول', labelStyle: TextStyle(color: Colors.grey))),
          TextField(controller: _cPassCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'كلمة السر', labelStyle: TextStyle(color: Colors.grey))),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (_cNameController.text.isNotEmpty && _cUserCtrl.text.isNotEmpty) {
                appState.addCourier(_cNameController.text, _cPhoneController.text, _cUserCtrl.text, _cPassCtrl.text);
                _cNameController.clear();
                _cPhoneController.clear();
                _cUserCtrl.clear();
                _cPassCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المندوب بنجاح!')));
              }
            },
            child: const Text('تسجيل المندوب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(AppState appState) {
    if (appState.notifications.isEmpty) {
      return const Center(child: Text('لا توجد تنبيهات حالياً', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: appState.notifications.length,
      itemBuilder: (context, index) {
        final notif = appState.notifications[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          child: ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.amber),
            title: Text(notif['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(notif['body'], style: const TextStyle(color: Colors.white70)),
          ),
        );
      },
    );
  }
}