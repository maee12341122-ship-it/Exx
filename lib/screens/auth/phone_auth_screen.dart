import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state.dart';
import '../customer/map_location_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const PhoneAuthScreen({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  int step = 1;
  String generatedOtp = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // دالة إرسال الرمز عبر الواتساب مباشرة
  Future<void> _sendWhatsAppOtp(String phone) async {
    // 1. توليد رمز عشوائي من 6 أرقام
    generatedOtp = (100000 + Random().nextInt(900000)).toString();

    // حفظ الرمز في الـ AppState لكي يتم التحقق منه لاحقاً
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setCustomGeneratedOtp(_phoneController.text, generatedOtp);

    // 2. تجهيز رسالة الواتساب للرقم المدخل
    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '967${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('967')) {
      formattedPhone = '967$formattedPhone';
    }

    String message = "مرحباً، رمز التحقق الخاص بك لتطبيق تعز إكسبريس هو: $generatedOtp";

    final Uri whatsappUri = Uri.parse(
      "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      setState(() => step = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الواتساب، تأكد من تثبيته')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A237E), // أزرق داكن فخم
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF283593),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user, size: 65, color: Colors.amberAccent),
                  const SizedBox(height: 15),
                  const Text(
                    'تعز إكسبرس\nبوابة المصادقة الآمنة',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),

                  // الخطوة 1: إدخال الرقم
                  if (step == 1) ...[
                    const Text('أدخل رقم هاتفك لإرسال رمز التحقق عبر واتساب', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.phone, color: Colors.amberAccent),
                        filled: true,
                        fillColor: const Color(0xFF121212),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_phoneController.text.length >= 9) {
                          _sendWhatsAppOtp(_phoneController.text);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال رقم هاتف صحيح')));
                        }
                      },
                      child: const Text('إرسال الكود عبر واتساب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],

                  // الخطوة 2: إدخال رمز التحقق
                  if (step == 2) ...[
                    const Text('أدخل الرمز الذي أرسلته عبر الواتساب', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '______',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF121212),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        // التحقق من تطابق الكود المدخل مع الكود المولد حصرياً
                        if (_otpController.text == generatedOtp) {
                          setState(() => step = 3);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز التحقق غير صحيح!')));
                        }
                      },
                      child: const Text('تحقق ومتابعة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],

                  // الخطوة 3: إدخال الاسم والموقع وحفظه في Supabase
                  if (step == 3) ...[
                    const Text('أدخل بياناتك الشخصية لإتمام التسجيل', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.person, color: Colors.amberAccent),
                        filled: true,
                        fillColor: const Color(0xFF121212),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'العنوان بالتفصيل',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.home, color: Colors.amberAccent),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map, color: Colors.amberAccent),
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
                        filled: true,
                        fillColor: const Color(0xFF121212),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_nameController.text.isNotEmpty && _addressController.text.isNotEmpty) {
                          appState.saveUserProfileDetails(_nameController.text, _addressController.text);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تفعيل الحساب وحفظه في قاعدة البيانات بنجاح! ✅')));
                          if (widget.onLoginSuccess != null) {
                            widget.onLoginSuccess!();
                          } else {
                            Navigator.pop(context);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال الاسم والعنوان')));
                        }
                      },
                      child: const Text('حفظ وبدء الاستخدام', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
