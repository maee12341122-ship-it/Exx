import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';

class OrdersScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const OrdersScreen({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppState>().orders;
    return Scaffold(
      appBar: AppBar(
        leading: onOpenDrawer == null ? null : IconButton(icon: const Icon(Icons.menu), onPressed: onOpenDrawer),
        title: const Text('طلباتي'),
      ),
      body: orders.isEmpty
          ? const EmptyState(message: 'لا توجد طلبات محفوظة حتى الآن', icon: Icons.receipt_long_outlined)
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: orders.length,
        itemBuilder: (context, index) => _orderCard(context, orders[index]),
      ),
    );
  }

  Widget _orderCard(BuildContext context, dynamic order) {
    // التعامل مع الطلب سواء كان Map (من Supabase مباشرة) أو كائن Model
    final orderId = order is Map ? (order['id']?.toString() ?? '') : order.id;
    final status = order is Map ? (order['status']?.toString() ?? 'waitingForPricing') : order.status;
    final totalPrice = order is Map ? (order['total_price']?.toString() ?? '0') : order.total.toString();
    final customerName = order is Map ? (order['customer_name']?.toString() ?? '') : order.customerName;
    final customerPhone = order is Map ? (order['phone']?.toString() ?? '') : order.customerPhone;
    final address = order is Map ? (order['address']?.toString() ?? '') : order.address;
    final itemsDesc = order is Map ? (order['items_description']?.toString() ?? 'لا توجد تفاصيل') : (order.itemsDescription ?? '');
    final productsTotal = order is Map ? (order['products_total']?.toString() ?? '0') : order.subtotal.toString();
    final deliveryFee = order is Map ? (order['delivery_fee']?.toString() ?? '0') : order.deliveryFee.toString();
    final assignedCourier = order is Map ? (order['assigned_courier']?.toString() ?? 'لم يتم التعيين') : order.assignedCourier;
    final adminMessage = order is Map ? (order['admin_message']?.toString() ?? '') : '';

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppConstants.gold,
          child: Icon(Icons.receipt, color: Colors.black),
        ),
        title: Text('طلب #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold)),
        subtitle: Text('الحالة: $status\nالإجمالي: $totalPrice ر.ي\nالمندوب: $assignedCourier'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_left),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('تفاصيل الطلب #$orderId'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الحالة: $status'),
                  if (adminMessage.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text('ملاحظة الإدارة: $adminMessage', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                  const Divider(),
                  Text('العميل: $customerName'),
                  Text('الهاتف: $customerPhone'),
                  Text('العنوان: $address'),
                  const Divider(),
                  Text('تفاصيل الطلب: $itemsDesc', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('سعر المنتجات: $productsTotal ر.ي'),
                  Text('رسوم التوصيل: $deliveryFee ر.ي'),
                  Text('الإجمالي الكلي: $totalPrice ر.ي', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('المندوب المعين: $assignedCourier'),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
          ),
        ),
      ),
    );
  }
}