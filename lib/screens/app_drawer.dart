import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../utils/constants.dart';
import 'delivery_login_screen.dart';

class AppDrawer extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const AppDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
            accountName: Text(user?.name ?? 'زائر تعز إكسبرس', style: const TextStyle(color: AppConstants.gold)),
            accountEmail: Text(user?.phone ?? 'لم يتم تسجيل رقم هاتف', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppConstants.gold,
              child: Icon(Icons.person, color: Colors.black, size: 34),
            ),
          ),
          _item(context, Icons.person_outline, 'حسابي', () => onNavigate(3)),
          _item(context, Icons.receipt_long, 'طلباتي', () => onNavigate(2)),
          _item(context, Icons.location_city, 'تغيير المدينة (تعز)', () {
            Navigator.pop(context);
            _showMessage(context, 'الخدمة الحالية متاحة في مدينة تعز فقط.');
          }),
          _item(context, Icons.phone, 'تواصل معنا', () {
            Navigator.pop(context);
            _showMessage(context, 'بيانات التواصل الرسمية غير مضافة بعد. أضف رقم الدعم قبل نشر التطبيق.');
          }),
          _item(context, Icons.privacy_tip_outlined, 'سياسة الخصوصية', () {
            Navigator.pop(context);
            _showTextDialog(context, 'سياسة الخصوصية',
                'في نسخة المرحلة الأولى تُحفظ بيانات التجربة محلياً على الجهاز. لا توجد مزامنة سحابية أو نظام صلاحيات خادمي بعد. لا تضع بيانات عملاء حقيقية قبل إعداد الخادم وقواعد الأمان.');
          }),
          _item(context, Icons.share, 'مشاركة التطبيق', () async {
            await Clipboard.setData(const ClipboardData(text: 'تعز إكسبرس - Taiz Express'));
            if (context.mounted) {
              Navigator.pop(context);
              _showMessage(context, 'تم نسخ اسم التطبيق. أضف رابط المتجر بعد نشر التطبيق.');
            }
          }),
          _item(context, Icons.info_outline, 'نبذة عن التطبيق وكيفية استخدامه', () {
            Navigator.pop(context);
            _showTextDialog(context, 'عن تعز إكسبرس',
                'تعز إكسبرس تطبيق توصيل تجريبي يجمع المطاعم والبقالات والخضار والفواكه والصيدلية والطلبات الخاصة في واجهة واحدة. هذه نسخة تطوير محلية للمرحلة الأولى.');
          }),
          _item(context, Icons.delivery_dining, 'تسجيل دخول المندوبين', () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeliveryLoginScreen()));
          }),
          _item(context, Icons.brightness_6, 'مظهر التطبيق', () => _showThemeDialog(context, state)),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('الإصدار: 2.1.0\nTaiz Express • المرحلة الأولى',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: AppConstants.gold), title: Text(title), onTap: onTap);
  }

  void _showThemeDialog(BuildContext context, AppState state) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('اختر مظهر التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeOption(dialogContext, state, ThemeMode.light, 'الوضع الفاتح'),
            _themeOption(dialogContext, state, ThemeMode.dark, 'الوضع الداكن'),
            _themeOption(dialogContext, state, ThemeMode.system, 'مطابق للنظام'),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, AppState state, ThemeMode mode, String label) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: state.themeMode,
      title: Text(label),
      onChanged: (value) {
        if (value != null) state.setThemeMode(value);
        Navigator.pop(context);
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showTextDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
      ),
    );
  }
}
