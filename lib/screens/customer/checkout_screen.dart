import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'map_location_screen.dart';
import '../auth/phone_auth_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'عميل تعز إكسبرس');
  final TextEditingController _addressController = TextEditingController(text: 'تعز - شارع جمال');

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // التحقق التلقائي: إذا لم يكن مسجلاً، وجهه لشاشة تسجيل الدخول فوراً
    if (appState.userProfile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PhoneAuthScreen(
              onLoginSuccess: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      });
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final String registeredPhone = appState.userProfile!['phone'] ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('تأكيد الطلب وإرسال البيانات', style: TextStyle(color: Colors.white)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 10),
                      Text('حسابك مسجل برقم: $registeredPhone', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Text('بيانات المستلم', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل الكامل',
                    labelStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 10),
                // رقم الهاتف مثبت ولا يتم طلبه مرة أخرى لأنه تم التحقق منه مسبقاً
                TextField(
                  enabled: false,
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف (تم التحقق منه)',
                    hintText: registeredPhone,
                    hintStyle: const TextStyle(color: Colors.amber),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'العنوان بالتفصيل (الشارع، الحارة...)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map, color: Colors.amber),
                      onPressed: () async {
                        final loc = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MapLocationScreen()),
                        );
                        if (loc != null && loc is String) {
                          setState(() {
                            _addressController.text = loc;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('ملخص سلة المشتريات', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي المنتجات:', style: TextStyle(color: Colors.white70)),
                    Text('${appState.totalAmount} ر.ي', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 5),
                const Text('ملاحظة: سيقوم المشرف بتحديد رسوم التوصيل وإرسالها لك في طلباتي للموافقة.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    if (_nameController.text.isNotEmpty && _addressController.text.isNotEmpty) {
                      final itemsDesc = appState.cartItems.map((e) => '${e.name} (${e.quantity} قطعه)').join(', ');
                      appState.createOrder(
                        customerName: _nameController.text,
                        phone: registeredPhone,
                        address: _addressController.text,
                        itemsDesc: itemsDesc,
                        productsTotal: appState.totalAmount,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال الطلب بنجاح إلى لوحة المشرف!')),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الرجاء إكمال الاسم والعنوان')),
                      );
                    }
                  },
                  child: const Text('إرسال الطلب للمشرف', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}