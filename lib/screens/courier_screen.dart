import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'chat_screen.dart';

class CourierScreen extends StatefulWidget {
  const CourierScreen({Key? key}) : super(key: key);

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final courier = appState.currentCourier;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(courier == null ? 'تسجيل دخول المندوب' : 'لوحة المندوب: ${courier['name']}', style: const TextStyle(color: Colors.white)),
          actions: [
            if (courier != null)
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: 'تسجيل الخروج',
                onPressed: () => appState.logoutCourier(),
              ),
          ],
        ),
        body: courier == null
            ? Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.two_wheeler, size: 70, color: Colors.amber),
                  const SizedBox(height: 20),
                  const Text('بوابة تسجيل دخول الكابتن (المندوب)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم',
                      labelStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'كلمة السر',
                      labelStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 45)),
                    onPressed: () {
                      bool success = appState.loginCourier(_usernameController.text.trim(), _passwordController.text.trim());
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('فشل الدخول: إما بيانات غير صحيحة أو أن الحساب مفتوح في جلسة أخرى حالياً!')),
                        );
                      }
                    },
                    child: const Text('دخول لوحة الطلبات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        )
            : _buildCourierOrdersList(appState, courier),
      ),
    );
  }

  Widget _buildCourierOrdersList(AppState appState, Map<String, dynamic> courier) {
    final String todayDate = DateTime.now().toString().split(' ')[0];

    // فلترة الطلبات المسندة للمندوب بناءً على الحقل الصحيح في Supabase
    final myOrders = appState.orders.where((o) {
      return o['assigned_courier'] == courier['name'];
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الكابتن: ${courier['name']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                Text('طلبات اليوم ($todayDate): ${myOrders.length}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: myOrders.isEmpty
                ? const Center(child: Text('لا توجد طلبات مسندة لك حالياً', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: myOrders.length,
              itemBuilder: (context, index) {
                final order = myOrders[index];
                final orderId = order['id'].toString();

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
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.amber),
                              tooltip: 'مراسلة المشرف',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      orderId: orderId,
                                      userRole: 'courier',
                                      targetChat: 'admin_courier',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('العنوان المطلوب: ${order['address'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('المنتجات: ${order['items_description'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('الإجمالي المطلوب: ${order['total_price'] ?? 0} ر.ي', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('الحالة: ${order['status'] ?? ''}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                        const Divider(color: Colors.grey),

                        // التسلسل الصحيح لأزرار المندوب:
                        if (order['status'] == 'waitingCourierApproval') ...[
                          const Text('هل تقبل توصيل هذا الطلب؟', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () {
                                    appState.courierRespondToOrder(orderId, true);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قَبِلت الطلب بنجاح 🟢')));
                                  },
                                  child: const Text('قبول الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    appState.courierRespondToOrder(orderId, false);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض الطلب وإعادته للإدارة 🔴')));
                                  },
                                  child: const Text('رفض الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ]
                        else if (order['status'] == 'onTheWay') ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 40)),
                            onPressed: () {
                              appState.courierUpdateArrival(orderId);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال إشعار الوصول للعميل والمشرف! 📍')));
                            },
                            child: const Text('هل وصلت إلى العميل؟ (نعم، وصلت)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ]
                        else if (order['status'] == 'arrived') ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 40)),
                              onPressed: () {
                                appState.markOrderDelivered(orderId);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تأكيد تسليم الطلب بنجاح! ✅')));
                              },
                              child: const Text('تم التسليم ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ]
                          else ...[
                              Text('ملاحظة: ${order['admin_message'] ?? ''}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                            ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}