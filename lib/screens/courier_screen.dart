import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

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
    final myOrders = appState.orders.where((o) {
      return o['assignedCourier'] == courier['name'];
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
                bool isWaitingResponse = order['status'] == 'assignedToCourier';

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('طلب #${order['id']} - العميل: ${order['customerName']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text('الهاتف: ${order['phone']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('العنوان: ${order['address']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('المنتجات: ${order['itemsDescription']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('الإجمالي المطلوب: ${order['totalPrice']} ر.ي', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        Text('الحالة: ${order['status']}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                        const Divider(color: Colors.grey),

                        // أزرار القبول أو الرفض للطلب
                        if (isWaitingResponse) ...[
                          const Text('هل تقبل توصيل هذا الطلب؟', style: TextStyle(color: Colors.amber, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () {
                                    appState.courierRespondToOrder(order['id'], true);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قَبِلت الطلب بنجاح!')));
                                  },
                                  child: const Text('قبول الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    appState.courierRespondToOrder(order['id'], false);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض الطلب وإرسال تنبيه للمشرف!')));
                                  },
                                  child: const Text('رفض الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ] else if (order['status'] == 'onTheWay') ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 35)),
                            onPressed: () {
                              appState.markOrderDelivered(order['id']);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تأكيد تسليم الطلب للعميل!')));
                            },
                            child: const Text('تأكيد تسليم الطلب للعميل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ] else ...[
                          Text('حالة الطلب: ${order['adminMessage']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
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