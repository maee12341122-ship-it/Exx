import 'address_model.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final AddressModel address;
  final List<CartItemModel> items;
  final int subtotal;
  final int deliveryFee;
  final int discount;
  final int total;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String? deliveryManId;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.deliveryManId,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  OrderModel copyWith({String? status, String? paymentStatus, String? deliveryManId, DateTime? updatedAt}) {
    return OrderModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      deliveryManId: deliveryManId ?? this.deliveryManId,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'address': address.toJson(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'total': total,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'status': status,
        'deliveryManId': deliveryManId,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String? ?? '',
        customerId: json['customerId'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        customerPhone: json['customerPhone'] as String? ?? '',
        address: AddressModel.fromJson(Map<String, dynamic>.from(json['address'] as Map? ?? {})),
        items: (json['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CartItemModel.fromJson)
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
        deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
        discount: (json['discount'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        paymentMethod: json['paymentMethod'] as String? ?? 'cash',
        paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
        status: json['status'] as String? ?? 'pending',
        deliveryManId: json['deliveryManId'] as String?,
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
