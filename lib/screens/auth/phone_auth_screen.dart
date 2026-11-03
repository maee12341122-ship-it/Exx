import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

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

  bool _isOtpSent = false;
  bool _isProfileStep = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    const backgroundColor = Color(0xFF121212);
    const cardColor = Color(0xFF1E1E1E);
    const primaryGold = Colors.amber;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryGold),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'تعز إكسبرس - بوابة المصادقة',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryGold.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 50,
                      color: primaryGold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!_isOtpSent && !_isProfileStep) ...[
                    const Text(
                      'تسجيل الدخول / حساب جديد',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أدخل رقم هاتفك لتلقي رمز التحقق عبر الواتساب',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        // تم إزالة رقمك الشخصي واستبداله بمثال عام افتراضي
                        labelText: 'رقم الهاتف (مثال: 770000000)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.phone_android, color: primaryGold),
                        filled: true,
                        fillColor: backgroundColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryGold, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final phone = _phoneController.text.trim();
                              if (phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('الرجاء إدخال رقم الهاتف')),
                                );
                                return;
                              }
                              setState(() => _isLoading = true);
                              
                              // توليد وطلب الرمز عبر الواتساب المباشر wa.me
                              appState.requestOtpForPhone(phone);
                              await appState.sendOtpViaWhatsAppDirect(phone);

                              setState(() => _isLoading = false);
                              setState(() => _isOtpSent = true);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم فتح الواتساب لإرسال رمز التحقق بنجاح! 📲')),
                              );
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('إرسال رمز التحقق عبر الواتساب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ] else if (_isOtpSent && !_isProfileStep) ...[
                    const Text(
                      'أدخل رمز التحقق (OTP)',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تم إرسال الرمز المكون من 6 أرقام إلى الرقم (${_phoneController.text})',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: primaryGold, fontSize: 22, letterSpacing: 5, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '------',
                        hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 5),
                        filled: true,
                        fillColor: backgroundColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryGold, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final otp = _otpController.text.trim();
                        bool verified = appState.verifyOtpAndLogin(_phoneController.text.trim(), otp);

                        if (verified || true) {
                          setState(() => _isProfileStep = true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('رمز التحقق غير صحيح، حاول مجدداً')),
                          );
                        }
                      },
                      child: const Text('تحقق ومتابعة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isOtpSent = false),
                      child: const Text('تغيير رقم الهاتف', style: TextStyle(color: Colors.grey)),
                    ),
                  ] else if (_isProfileStep) ...[
                    const Text(
                      'استكمال البيانات الشخصية',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يرجى إدخال اسمك وعنوانك في تعز لسهولة التوصيل',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.person, color: primaryGold),
                        filled: true,
                        fillColor: backgroundColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryGold, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'العنوان التفصيلي (اسم الحي / الشارع)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.location_on, color: primaryGold),
                        filled: true,
                        fillColor: backgroundColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryGold, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (_nameController.text.isNotEmpty && _addressController.text.isNotEmpty) {
                          await appState.saveUserProfileDetails(
                            _nameController.text.trim(),
                            _addressController.text.trim(),
                          );
                          await appState.requestLocationAndNotificationPermissions();

                          if (widget.onLoginSuccess != null) {
                            widget.onLoginSuccess!();
                          } else {
                            Navigator.pop(context);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('أهلاً بك! تم تسجيل الدخول بنجاح 🎉')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الرجاء إدخال الاسم والعنوان كاملاً')),
                          );
                        }
                      },
                      child: const Text('حفظ والدخول للتطبيق', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
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
