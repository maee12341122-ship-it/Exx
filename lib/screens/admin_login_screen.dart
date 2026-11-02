import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإدارة')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings_outlined, size: 76, color: AppConstants.gold),
            const SizedBox(height: 18),
            const Text(
              'معاينة لوحة الإدارة\nالمرحلة الأولى',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'أزلنا كلمة المرور الثابتة. هذه الصفحة وضع تطوير محلي مفتوح وليست تسجيل دخول آمناً. '
                  'لا تنشر هذه النسخة ولا تستخدمها لإدارة طلبات حقيقية قبل إضافة مصادقة وصلاحيات خادمية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orangeAccent, height: 1.7),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminDashboard()),
                ),
                child: const Text('الدخول إلى وضع المعاينة المحلي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}