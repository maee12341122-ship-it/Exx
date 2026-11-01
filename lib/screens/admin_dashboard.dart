import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/delivery_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/empty_state.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة تعز إكسبرس'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag), text: 'الطلبات'),
              Tab(icon: Icon(Icons.delivery_dining), text: 'المندوبون'),
              Tab(icon: Icon(Icons.inventory_2), text: 'المنتجات والإعدادات'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [AdminOrdersTab(), AdminCouriersTab(), AdminProductsSettingsTab()],
        ),
      ),
    );
  }
}

class AdminOrdersTab extends StatelessWidget {
  const AdminOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppState>().orders;
    if (orders.isEmpty) return const EmptyState(message: 'لا توجد طلبات محفوظة على هذا الجهاز', icon: Icons.receipt_long);
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: orders.length,
      itemBuilder: (context, index) => _AdminOrderCard(order: orders[index]),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final courier = state.couriers.where((item) => item.id == order.deliveryManId).firstOrNull;
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('طلب ${order.id}', style: const TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('العميل: ${order.customerName} • ${order.customerPhone}'),
            Text('العنوان: ${order.address.area} - ${order.address.details}'),
            if (order.address.hasCoordinates)
              Text('الإحداثيات: ${order.address.latitude}, ${order.address.longitude}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 5),
            ...order.items.map((item) => Text('${item.name} × ${item.quantity} = ${item.lineTotal} ر.ي', style: const TextStyle(fontSize: 12))),
            const Divider(),
            Text('المجموع ${order.subtotal} + التوصيل ${order.deliveryFee} = ${order.total} ر.ي'),
            Text('الدفع: نقداً عند الاستلام • الحالة: ${order.paymentStatus == PaymentStatuses.paid ? 'تم التحصيل' : 'غير مدفوع'}'),
            Text('الحالة: ${OrderStatuses.label(order.status)}'),
            if (courier != null) Text('المندوب: ${courier.name} • ${courier.phone}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (order.status == OrderStatuses.pending)
                  _action(context, 'قبول', () => state.updateOrderStatus(order.id, OrderStatuses.accepted)),
                if (order.status == OrderStatuses.accepted)
                  _action(context, 'بدء التجهيز', () => state.updateOrderStatus(order.id, OrderStatuses.preparing)),
                if (order.status == OrderStatuses.preparing)
                  _action(context, 'جاهز للاستلام', () => state.updateOrderStatus(order.id, OrderStatuses.ready)),
                if (order.status == OrderStatuses.ready && order.deliveryManId == null)
                  _action(context, 'تعيين مندوب', () => _assignCourier(context, order.id)),
                if (order.status != OrderStatuses.delivered && order.status != OrderStatuses.cancelled)
                  _action(context, 'إلغاء الطلب', () => _cancelOrder(context, order.id), danger: true),
                if (order.paymentStatus == PaymentStatuses.awaitingVerification)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('لا يمكن اعتماد التحويل قبل إضافة إثبات الدفع وربطه بخادم في مرحلة الدفع.',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, String label, VoidCallback onPressed, {bool danger = false}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(foregroundColor: danger ? Colors.redAccent : AppConstants.gold),
      child: Text(label),
    );
  }

  Future<void> _assignCourier(BuildContext context, String orderId) async {
    final state = context.read<AppState>();
    final available = state.couriers.where((courier) => courier.canReceiveOrders).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد مندوب متاح. أضف مندوباً أو غيّر حالته أولاً.')));
      return;
    }
    final selectedId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('اختيار المندوب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: available
              .map((courier) => ListTile(
                    leading: const Icon(Icons.delivery_dining, color: AppConstants.gold),
                    title: Text(courier.name),
                    subtitle: Text(courier.phone),
                    onTap: () => Navigator.pop(dialogContext, courier.id),
                  ))
              .toList(),
        ),
      ),
    );
    if (selectedId == null || !context.mounted) return;
    try {
      state.assignOrderToCourier(orderId, selectedId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعيين الطلب للمندوب محلياً.')));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('إلغاء الطلب'),
            content: const Text('هل تريد إلغاء هذا الطلب؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('تراجع')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('إلغاء الطلب')),
            ],
          ),
        ) ??
        false;
    if (shouldCancel && context.mounted) context.read<AppState>().updateOrderStatus(orderId, OrderStatuses.cancelled);
  }
}

class AdminCouriersTab extends StatelessWidget {
  const AdminCouriersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCourier(context),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة مندوب'),
      ),
      body: state.couriers.isEmpty
          ? const EmptyState(message: 'لم تتم إضافة مندوبين بعد', icon: Icons.delivery_dining)
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 85, top: 8),
              itemCount: state.couriers.length,
              itemBuilder: (context, index) {
                final courier = state.couriers[index];
                return Card(
                  color: Theme.of(context).colorScheme.surface,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: courier.canReceiveOrders ? Colors.green : Colors.red,
                      child: const Icon(Icons.delivery_dining, color: Colors.white),
                    ),
                    title: Text(courier.name),
                    subtitle: Text(
                      '${courier.phone}\n${courier.isEnabled ? (courier.isAvailable ? 'متاح' : 'مشغول / غير متاح') : 'موقوف'}'
                      ' • الطلب الحالي: ${courier.currentOrderId ?? 'لا يوجد'} • المكتملة اليوم: ${courier.completedToday}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'toggle') {
                          try {
                            state.updateCourier(courier.copyWith(isEnabled: !courier.isEnabled));
                          } catch (error) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                          }
                        } else if (value == 'edit') {
                          _editCourier(context, courier);
                        } else if (value == 'available') {
                          state.setCourierAvailability(courier.id, !courier.isAvailable);
                        } else if (value == 'delete') {
                          state.removeCourier(courier.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
                        PopupMenuItem(value: 'toggle', child: Text(courier.isEnabled ? 'تعطيل المندوب' : 'تفعيل المندوب')),
                        PopupMenuItem(value: 'available', child: Text(courier.isAvailable ? 'جعله مشغولاً' : 'جعله متاحاً')),
                        const PopupMenuItem(value: 'delete', child: Text('حذف المندوب')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editCourier(BuildContext context, DeliveryModel courier) async {
    final nameController = TextEditingController(text: courier.name);
    final phoneController = TextEditingController(text: courier.phone);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('تعديل بيانات المندوب'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المندوب'), validator: Validators.requiredText),
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
      try {
        context.read<AppState>().updateCourier(courier.copyWith(
              name: nameController.text.trim(),
              phone: phoneController.text,
            ));
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> _addCourier(BuildContext context) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('إضافة مندوب'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المندوب'), validator: Validators.requiredText),
                  const SizedBox(height: 10),
                  TextFormField(controller: phoneController, keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'رقم الهاتف اليمني'), validator: Validators.yemeniPhone),
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
      try {
        context.read<AppState>().addCourier(name: nameController.text, phone: phoneController.text);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
    nameController.dispose();
    phoneController.dispose();
  }
}

class AdminProductsSettingsTab extends StatefulWidget {
  const AdminProductsSettingsTab({super.key});

  @override
  State<AdminProductsSettingsTab> createState() => _AdminProductsSettingsTabState();
}

class _AdminProductsSettingsTabState extends State<AdminProductsSettingsTab> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _startController = TextEditingController(text: state.workStartHour.toString());
    _endController = TextEditingController(text: state.workEndHour.toString());
    _feeController = TextEditingController(text: state.deliveryFee.toString());
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        const Text('أوقات الدوام ورسوم التوصيل', style: TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(controller: _startController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بداية الدوام (0-23)'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _endController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نهاية الدوام (1-24)'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _feeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'التوصيل'))),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            final start = int.tryParse(_startController.text);
            final end = int.tryParse(_endController.text);
            final fee = int.tryParse(_feeController.text);
            if (start == null || end == null || fee == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل أرقاماً صحيحة.')));
              return;
            }
            try {
              state.updateBusinessSettings(startHour: start, endHour: end, deliveryFee: fee);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات محلياً.')));
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
            }
          },
          child: const Text('حفظ الإعدادات'),
        ),
        const Divider(height: 28),
        Row(
          children: [
            const Expanded(child: Text('المنتجات', style: TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold, fontSize: 16))),
            TextButton.icon(onPressed: () => _editProduct(context), icon: const Icon(Icons.add), label: const Text('إضافة')),
          ],
        ),
        ...state.products.map((product) => Card(
              color: Theme.of(context).colorScheme.surface,
              child: ListTile(
                title: Text(product.name),
                subtitle: Text('${product.storeName} • ${product.price} ر.ي • ${product.isAvailable ? 'متوفر' : 'غير متوفر'}'),
                leading: Icon(product.isAvailable ? Icons.check_circle : Icons.pause_circle, color: product.isAvailable ? Colors.green : Colors.red),
                onTap: () => _editProduct(context, product: product),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => state.removeProduct(product.id),
                ),
              ),
            )),
        const SizedBox(height: 8),
        const Text(
          'هذه التعديلات محفوظة على هذا الجهاز فقط. في النسخة التجارية يجب أن تأتي المنتجات والأسعار والإعدادات من قاعدة بيانات الخادم.',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _editProduct(BuildContext context, {ProductModel? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final storeController = TextEditingController(text: product?.storeName ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    bool isAvailable = product?.isAvailable ?? true;
    String category = product?.category ?? ProductCategories.groceries;
    final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(product == null ? 'إضافة منتج' : 'تعديل المنتج'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المنتج')),
                    const SizedBox(height: 8),
                    TextField(controller: storeController, decoration: const InputDecoration(labelText: 'اسم المتجر')),
                    const SizedBox(height: 8),
                    TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر')),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('المنتج متوفر لدى المتجر'),
                      value: isAvailable,
                      onChanged: (value) => setDialogState(() => isAvailable = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: ProductCategories.all
                          .where((item) => item != ProductCategories.custom)
                          .map((item) => DropdownMenuItem(value: item, child: Text(ProductCategories.label(item))))
                          .toList(),
                      onChanged: (value) => setDialogState(() => category = value ?? category),
                      decoration: const InputDecoration(labelText: 'القسم'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        storeController.text.trim().isEmpty ||
                        int.tryParse(priceController.text) == null ||
                        int.parse(priceController.text) < 0) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (saved && context.mounted) {
      final state = context.read<AppState>();
      state.upsertProduct(ProductModel(
        id: product?.id ?? 'prod-${DateTime.now().microsecondsSinceEpoch}',
        name: nameController.text.trim(),
        storeName: storeController.text.trim(),
        category: category,
        price: int.parse(priceController.text),
        imageUrl: product?.imageUrl ?? '',
        unit: product?.unit ?? 'حبة',
        description: product?.description ?? '',
        isAvailable: isAvailable,
      ));
    }
    nameController.dispose();
    storeController.dispose();
    priceController.dispose();
  }
}

extension _AdminFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
