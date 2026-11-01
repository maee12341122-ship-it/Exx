import 'dart:math';
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class AppState extends ChangeNotifier {
  int startHour = 11;
  int endHour = 22;

  bool isDarkMode = true;
  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  String currentCity = 'تعز';
  void setCity(String city) {
    currentCity = city;
    if (userProfile != null) {
      userProfile!['city'] = city;
    }
    notifyListeners();
  }

  void setWorkingHours(int start, int end) {
    startHour = start;
    endHour = end;
    notifyListeners();
  }

  bool get isStoreOpen {
    final now = DateTime.now();
    return now.hour >= startHour && now.hour < endHour;
  }

  final String adminPassword = 'maeen775145534@';
  bool isAdminLoggedIn = false;

  bool loginAdmin(String password) {
    if (password == adminPassword) {
      if (isAdminLoggedIn) return false;
      isAdminLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logoutAdmin() {
    isAdminLoggedIn = false;
    notifyListeners();
  }

  Map<String, String>? userProfile;
  String? generatedDynamicOtp;

  void requestOtpForPhone(String phone) {
    final randomOtp = (100000 + Random().nextInt(900000)).toString();
    generatedDynamicOtp = randomOtp;
    debugPrint('====================================');
    debugPrint('🔐 كود التحقق (OTP) الحقيقي لرقم $phone هو: $randomOtp');
    debugPrint('====================================');
  }

  bool verifyOtpAndLogin(String phone, String enteredOtp) {
    if (generatedDynamicOtp != null && enteredOtp == generatedDynamicOtp) {
      userProfile = {
        'phone': phone,
        'name': '',
        'city': currentCity,
        'address': '',
      };
      notifyListeners();
      return true;
    }
    return false;
  }

  void saveUserProfileDetails(String name, String address) {
    if (userProfile != null) {
      userProfile!['name'] = name;
      userProfile!['address'] = address;
      notifyListeners();
    }
  }

  void logoutUser() {
    userProfile = null;
    notifyListeners();
  }

  Map<String, dynamic>? currentCourier;

  List couriers = [
    {
      'deliveryManId': 'D-001',
      'username': 'ahmed',
      'password': '123',
      'name': 'أحمد علي',
      'phone': '775145534',
      'status': 'available',
      'isLoggedIn': false,
      'completedOrders': 14,
    },
    {
      'deliveryManId': 'D-002',
      'username': 'mohammed',
      'password': '123',
      'name': 'محمد خالد',
      'phone': '773221144',
      'status': 'available',
      'isLoggedIn': false,
      'completedOrders': 8,
    },
  ];

  bool loginCourier(String username, String password) {
    final index = couriers.indexWhere(
          (c) => c['username'] == username && c['password'] == password,
    );
    if (index != -1) {
      if (couriers[index]['isLoggedIn'] == true) return false;
      couriers[index]['isLoggedIn'] = true;
      currentCourier = couriers[index];
      notifyListeners();
      return true;
    }
    return false;
  }

  void logoutCourier() {
    if (currentCourier != null) {
      final index = couriers.indexWhere((c) => c['deliveryManId'] == currentCourier!['deliveryManId']);
      if (index != -1) {
        couriers[index]['isLoggedIn'] = false;
      }
      currentCourier = null;
      notifyListeners();
    }
  }

  void addCourier(String name, String phone, String username, String password) {
    couriers.add({
      'deliveryManId': 'D-00${couriers.length + 1}',
      'username': username,
      'password': password,
      'name': name,
      'phone': phone,
      'status': 'available',
      'isLoggedIn': false,
      'completedOrders': 0,
    });
    notifyListeners();
  }

  final List<CartItemModel> _cartItems = [];
  List<CartItemModel> get cartItems => _cartItems;

  int get totalCartItemsCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  int getProductQuantityInCart(String productId) {
    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index >= 0) return _cartItems[index].quantity;
    return 0;
  }

  void addToCart(CartItemModel item) {
    final index = _cartItems.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      _cartItems[index].quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int delta) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _cartItems[index].quantity += delta;
      if (_cartItems[index].quantity <= 0) {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  List products = [
    ProductModel(
      id: '1',
      name: 'وجبة مشكل سفري',
      restaurantName: 'مطعم الشيباني',
      price: 3500.0,
      category: 'المطاعم',
      available: true,
      imageUrl: '',
    ),
    ProductModel(
      id: '2',
      name: 'مظبي لحم',
      restaurantName: 'مطعم الشيباني',
      price: 5000.0,
      category: 'المطاعم',
      available: true,
      imageUrl: '',
    ),
  ];

  void addProduct(ProductModel product) {
    products.add(product);
    notifyListeners();
  }

  void addCustomOrderToCart({required String customName, required double estimatedPrice}) {
    _cartItems.add(CartItemModel(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: 'طلب خاص: $customName',
      price: estimatedPrice,
      quantity: 1,
      restaurantId: 'خدمة الطلبات الخاصة',
      imageUrl: '',
    ));
    notifyListeners();
  }

  void toggleProductAvailability(String id) {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final p = products[index];
      products[index] = ProductModel(
        id: p.id,
        name: p.name,
        restaurantName: p.restaurantName,
        price: p.price,
        category: p.category,
        available: !p.available,
        imageUrl: p.imageUrl,
        unit: p.unit,
      );
      notifyListeners();
    }
  }

  List orders = [];

  void createOrder({
    required String customerName,
    required String phone,
    required String address,
    required String itemsDesc,
    required double productsTotal,
  }) {
    userProfile = {
      'phone': phone,
      'name': customerName,
      'city': currentCity,
      'address': address,
    };

    orders.add({
      'id': 'TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'itemsDescription': itemsDesc,
      'productsTotal': productsTotal,
      'deliveryFee': 0.0,
      'totalPrice': productsTotal,
      'assignedCourier': 'لم يتم التعيين',
      'status': 'waitingForPricing',
      'isFeeSent': false, // مؤشر هل أرسل المشرف الرسوم أم لا
      'adminMessage': 'بانتظار تحديد رسوم التوصيل من المشرف',
      'date': DateTime.now().toString().split(' ')[0],
    });
    clearCart();
    notifyListeners();
  }

  // المشرف يحدد رسوم التوصيل ويقيد الطلب مع تفعيل زر التعديل
  void setOrderDeliveryFee(String orderId, double fee, String courierName) {
    final index = orders.indexWhere((o) => o['id'].toString() == orderId);
    if (index != -1) {
      orders[index]['deliveryFee'] = fee;
      orders[index]['totalPrice'] = (orders[index]['productsTotal'] as double) + fee;
      orders[index]['assignedCourier'] = courierName;
      orders[index]['status'] = 'pricingSentToCustomer';
      orders[index]['isFeeSent'] = true; // تقييد الحقل للمشرف
      orders[index]['adminMessage'] = 'تم إرسال التسعيرة للمندوب والعميل بانتظار الرد ⏳';
      notifyListeners();
    }
  }

  // السماح للمشرف بفتح التقييد والتعديل
  void enableOrderFeeEditing(String orderId) {
    final index = orders.indexWhere((o) => o['id'].toString() == orderId);
    if (index != -1) {
      orders[index]['isFeeSent'] = false; // إلغاء التقييد مؤقتاً للتعديل
      notifyListeners();
    }
  }

  void courierRespondToOrder(String orderId, bool accepted) {
    final index = orders.indexWhere((o) => o['id'].toString() == orderId);
    if (index != -1) {
      final courierName = orders[index]['assignedCourier'];
      if (accepted) {
        orders[index]['status'] = 'onTheWay';
        orders[index]['adminMessage'] = 'المندوب ($courierName) قَبِل الطلب وهو في الطريق الآن 🟢';
        final courierIndex = couriers.indexWhere((c) => c['name'] == courierName);
        if (courierIndex != -1) {
          couriers[courierIndex]['status'] = 'busy';
          couriers[courierIndex]['completedOrders'] = (couriers[courierIndex]['completedOrders'] ?? 0) + 1;
        }
      } else {
        orders[index]['status'] = 'rejectedByCourier';
        orders[index]['adminMessage'] = '⚠️ تنبيه للمشرف: المندوب ($courierName) رَفَض الطلب! يرجى إسناده لمندوب آخر.';
        orders[index]['assignedCourier'] = 'لم يتم التعيين';
        orders[index]['isFeeSent'] = false; // فتح التقييد ليتمكن المشرف من إعادة الإسناد
      }
      notifyListeners();
    }
  }

  void customerRespondToPricing(String orderId, bool accepted) {
    final index = orders.indexWhere((o) => o['id'].toString() == orderId);
    if (index != -1) {
      if (accepted) {
        orders[index]['status'] = 'onTheWay';
        orders[index]['adminMessage'] = 'تمت موافقة العميل على التسعيرة والطلب قيد التوصيل ✅';
      } else {
        orders[index]['status'] = 'cancelledByCustomer';
        orders[index]['adminMessage'] = 'تم إلغاء الطلب من قِبل العميل.';
      }
      notifyListeners();
    }
  }

  void markOrderDelivered(String orderId) {
    final index = orders.indexWhere((o) => o['id'].toString() == orderId);
    if (index != -1) {
      orders[index]['status'] = 'delivered';
      orders[index]['adminMessage'] = 'تم تسليم الطلب بنجاح للعميل ✅';
      notifyListeners();
    }
  }
}