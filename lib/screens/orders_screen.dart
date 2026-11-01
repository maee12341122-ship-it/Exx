import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
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

  Widget _orderCard(BuildContext context, OrderModel order) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppConstants.gold,
          child: Icon(Icons.receipt, color: Colors.black),
        ),
        title: Text('طلب ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold)),
        subtitle: Text('${OrderStatuses.label(order.status)}\n${order.total} ر.ي • ${_paymentLabel(order)}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_left),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('تفاصيل الطلب ${order.id}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الحالة: ${OrderStatuses.label(order.status)}'),
                  Text('العميل: ${order.customerName}'),
                  Text('الهاتف: ${order.customerPhone}'),
                  Text('العنوان: ${order.address.area} - ${order.address.details}'),
                  const Divider(),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text('${item.name} × ${item.quantity} = ${item.lineTotal} ر.ي'),
                      )),
                  const Divider(),
                  Text('المنتجات: ${order.subtotal} ر.ي'),
                  Text('التوصيل: ${order.deliveryFee} ر.ي'),
                  Text('الإجمالي: ${order.total} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('حالة الدفع: ${order.paymentStatus == PaymentStatuses.paid ? 'تم التحصيل' : 'غير مدفوع'}'),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
          ),
        ),
      ),
    );
  }

  String _paymentLabel(OrderModel order) => (order.paymentMethod == 'cash' || order.paymentMethod == 'cash_on_delivery') ? 'نقداً عند الاستلام' : 'غير مدعوم';
}
