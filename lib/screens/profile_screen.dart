import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/address_model.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'location_picker_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const ProfileScreen({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: onOpenDrawer == null ? null : IconButton(icon: const Icon(Icons.menu), onPressed: onOpenDrawer),
          title: const Text('حسابي'),
        ),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: const Text('تسجيل بيانات العميل'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(leading: onOpenDrawer == null ? null : IconButton(icon: const Icon(Icons.menu), onPressed: onOpenDrawer), title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(radius: 34, backgroundColor: AppConstants.gold, child: Icon(Icons.person, color: Colors.black, size: 36)),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user.phone, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _editProfile(context, user.name, user.phone),
                    icon: const Icon(Icons.edit),
                    label: const Text('تعديل البيانات'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('العناوين المحفوظة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConstants.gold))),
              TextButton.icon(onPressed: () => _addAddress(context), icon: const Icon(Icons.add), label: const Text('إضافة عنوان')),
            ],
          ),
          if (user.addresses.isEmpty) const Text('لا توجد عناوين محفوظة'),
          ...user.addresses.map((address) => Card(
                color: Theme.of(context).colorScheme.surface,
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: AppConstants.gold),
                  title: Text(address.title),
                  subtitle: Text('${address.area} - ${address.details}'),
                  trailing: user.defaultAddress?.id == address.id
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : TextButton(onPressed: () => context.read<AppState>().setDefaultAddress(address.id), child: const Text('استخدام')),
                ),
              )),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('سيتم حذف بيانات العميل من هذا الجهاز فقط، وتبقى الطلبات المحلية محفوظة.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
                        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('خروج')),
                      ],
                    ),
                  ) ??
                  false;
              if (confirm && context.mounted) {
                context.read<AppState>().clearUser();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج من هذا الجهاز'),
          ),
          const SizedBox(height: 12),
          const Text('الحساب في هذه النسخة محفوظ محلياً، وليس حساباً موثقاً عبر خادم.',
              style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, String oldName, String oldPhone) async {
    final nameController = TextEditingController(text: oldName);
    final phoneController = TextEditingController(text: oldPhone);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('تعديل بيانات العميل'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم'), validator: Validators.requiredText),
                  const SizedBox(height: 10),
                  TextFormField(controller: phoneController, keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'رقم الهاتف'), validator: Validators.yemeniPhone),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, formKey.currentState!.validate()), child: const Text('حفظ')),
            ],
          ),
        ) ??
        false;
    if (saved && context.mounted) {
      context.read<AppState>().updateUser(name: nameController.text, phone: phoneController.text);
    }
    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> _addAddress(BuildContext context) async {
    final areaController = TextEditingController(text: 'شارع جمال');
    final detailsController = TextEditingController();
    LatLng? point;
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('إضافة عنوان جديد'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: areaController, decoration: const InputDecoration(labelText: 'المنطقة')),
                const SizedBox(height: 10),
                TextField(controller: detailsController, maxLines: 2, decoration: const InputDecoration(labelText: 'العنوان التفصيلي')),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final selected = await Navigator.of(context).push<LatLng>(
                      MaterialPageRoute(builder: (_) => LocationPickerScreen(initialPoint: point)),
                    );
                    if (selected != null) point = selected;
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('تحديد الموقع على الخريطة'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, detailsController.text.trim().isNotEmpty),
                child: const Text('حفظ العنوان'),
              ),
            ],
          ),
        ) ??
        false;
    if (saved && context.mounted) {
      context.read<AppState>().addOrUpdateAddress(AddressModel(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: 'عنوان ${DateTime.now().hour}:${DateTime.now().minute}',
            area: areaController.text.trim(),
            details: detailsController.text.trim(),
            latitude: point?.latitude,
            longitude: point?.longitude,
          ));
    }
    areaController.dispose();
    detailsController.dispose();
  }
}
