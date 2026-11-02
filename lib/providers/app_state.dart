import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class ChatMessage {
  final String id;
  final String orderId;
  final String senderRole;
  final String targetChat;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderRole,
    required this.targetChat,
    required this.message,
    required this.timestamp,
  });
}

class AppState extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  AppState() {
    _loadAdminSession();
    _loadCourierSession();
    fetchStoreSettings(); // جلب أوقات الدوام من السيرفر عند بدء التشغيل
    fetchProductsFromSupabase();
    fetchCouriersFromSupabase();
    listenToOrdersRealtime();
    listenToStoreSettingsRealtime(); // الاستماع الفوري لأي تغيير في أوقات الدوام من المشرف
  }

  int startHour = 8;
  int endHour = 24;

  // دالة لجلب أوقات العمل من جدول settings في Supabase
  Future<void> fetchStoreSettings() async {
    try {
      final response = await supabase.from('settings').select().maybeSingle();
      if (response != null) {
        startHour = int.tryParse(response['start_hour'].toString()) ?? 8;
        endHour = int.tryParse(response['end_hour'].toString()) ?? 24;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في جلب إعدادات الدوام من Supabase: $e');
    }
  }

  // الاستماع اللحظي لتغييرات أوقات الدوام بين المشرف والعميل
  void listenToStoreSettingsRealtime() {
    try {
      supabase.from('settings').stream(primaryKey: ['id']).listen((data) {
        if (data.isNotEmpty) {
          startHour = int.tryParse(data.first['start_hour'].toString()) ?? 8;
          endHour = int.tryParse(data.first['end_hour'].toString()) ?? 24;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('⚠️ خطأ في الاستماع اللحظي للإعدادات: $e');
    }
  }

  // دالة تحديث أوقات الدوام وحفظها سحابياً لكي تنعكس عند الطرفين فوراً
  Future<void> updateStoreSettings(int start, int end) async {
    startHour = start;
    endHour = end;
    notifyListeners();

    try {
      await supabase.from('settings').upsert({
        'id': 1, // صف إعدادات المتجر الثابت
        'start_hour': start,
        'end_hour': end,
      });
      debugPrint('✅ تم تحديث وحفظ أوقات الدوام سحابياً بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ أوقات الدوام في Supabase: $e');
    }
  }

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

  // دالة فحص حالة المتجر بناءً على الساعات المحددة
  bool get isStoreOpen {
    final now = DateTime.now();
    final currentHour = now.hour;
    if (endHour > startHour) {
      return currentHour >= startHour && currentHour < endHour;
    } else {
      return currentHour >= startHour || currentHour < endHour;
    }
  }

  final String adminPassword = 'maeen775145534@';
  bool isAdminLoggedIn = false;

  void _loadAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    isAdminLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
    notifyListeners();
  }

  bool loginAdmin(String password) {
    if (password == adminPassword) {
      isAdminLoggedIn = true;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('isAdminLoggedIn', true);
      });
      notifyListeners();
      return true;
    }
    return false;
  }

  void logoutAdmin() {
    isAdminLoggedIn = false;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isAdminLoggedIn', false);
    });
    notifyListeners();
  }

  Map<String, String>? userProfile;
  String? generatedDynamicOtp;

  void requestOtpForPhone(String phone) {
    final randomOtp = (100000 + Random().nextInt(900000)).toString();
    generatedDynamicOtp = randomOtp;
    notifyListeners();
  }

  void setCustomGeneratedOtp(String phone, String otp) {
    generatedDynamicOtp = otp;
    notifyListeners();
  }

  Future<bool> sendOtpViaServerWhatsApp(String recipientPhone) async {
    if (generatedDynamicOtp == null) return false;

    String formattedPhone = recipientPhone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '967${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('967')) {
      formattedPhone = '967$formattedPhone';
    }

    final messageText =
        '🌟 تطبيق تعز إكسبريس (Taiz Express) 🌟\n\n'
        'أهلاً بك!\n'
        'رمز التحقق الخاص بك هو: *$generatedDynamicOtp*\n\n'
        'لا تشارك هذا الرمز مع أي شخص حفاظاً على أمان حسابك. 🚀';

    const instanceId = 'YOUR_INSTANCE_ID';
    const token = 'YOUR_API_TOKEN';

    final url = Uri.parse('https://api.ultramsg.com/$instanceId/messages/chat');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'token': token, 'to': formattedPhone, 'body': messageText},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['sent'] == 'true' || jsonResponse['status'] == 'success') {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool verifyOtpAndLogin(String phone, String enteredOtp) {
    if (generatedDynamicOtp != null && enteredOtp == generatedDynamicOtp) {
      userProfile = {'phone': phone, 'name': '', 'city': currentCity, 'address': ''};
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> saveUserProfileDetails(String name, String address) async {
    if (userProfile != null) {
      userProfile!['name'] = name;
      userProfile!['address'] = address;
      
      String phone = userProfile!['phone'] ?? '';

      try {
        await supabase.from('customers').upsert({
          'phone': phone,
          'name': name,
          'city': address,
        }, onConflict: 'phone');

        debugPrint('✅ تم حفظ بيانات العميل في Supabase بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في حفظ بيانات العميل: $e');
      }

      notifyListeners();
    }
  }

  void logoutUser() {
    userProfile = null;
    notifyListeners();
  }

  Map<String, dynamic>? currentCourier;
  List couriers = [];

  void _loadCourierSession() async {
    final prefs = await SharedPreferences.getInstance();
    final courierId = prefs.getString('loggedCourierId');
    if (courierId != null && couriers.isNotEmpty) {
      final index = couriers.indexWhere((c) => c['id'].toString() == courierId || c['delivery_man_id'].toString() == courierId);
      if (index != -1) {
        currentCourier = couriers[index];
        notifyListeners();
      }
    }
  }

  Future<void> fetchCouriersFromSupabase() async {
    try {
      final response = await supabase.from('couriers').select();
      couriers = response;
      _loadCourierSession();
      notifyListeners();
    } catch (e) {
      debugPrint('خطأ في جلب المناديب: $e');
    }
  }

  Future<void> addCourier(String name, String phone, String username, String password) async {
    try {
      final courierId = 'D-00${couriers.length + 1}';
      await supabase.from('couriers').insert({
        'id': courierId,
        'delivery_man_id': courierId,
        'username': username,
        'password': password,
        'name': name,
        'phone': phone,
        'status': 'available',
        'is_logged_in': false,
        'completed_orders': 0,
      });
      fetchCouriersFromSupabase();
    } catch (e) {
      debugPrint('خطأ في إضافة المندوب: $e');
    }
  }

  bool loginCourier(String username, String password) {
    final index = couriers.indexWhere((c) => c['username'] == username && c['password'] == password);
    if (index != -1) {
      couriers[index]['is_logged_in'] = true;
      currentCourier = couriers[index];

      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('loggedCourierId', currentCourier!['id']?.toString() ?? currentCourier!['delivery_man_id'].toString());
      });

      notifyListeners();
      return true;
    }
    return false;
  }

  void logoutCourier() {
    if (currentCourier != null) {
      final index = couriers.indexWhere((c) => c['delivery_man_id'] == currentCourier!['delivery_man_id'] || c['id'] == currentCourier!['id']);
      if (index != -1) {
        couriers[index]['is_logged_in'] = false;
      }
      currentCourier = null;
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('loggedCourierId');
      });
      notifyListeners();
    }
  }

  final List<CartItemModel> _cartItems = [];
  List<CartItemModel> get cartItems => _cartItems;

  int get totalCartItemsCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

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

  List products = [];

  Future<void> fetchProductsFromSupabase() async {
    try {
      final response = await supabase.from('products').select();
      products = response.map((p) => ProductModel(
        id: p['id'].toString(),
        name: p['name'] ?? '',
        restaurantName: p['restaurant_name'] ?? 'متجر عام',
        price: double.tryParse(p['price'].toString()) ?? 0.0,
        category: p['category'] ?? 'المطاعم',
        available: p['available'] ?? true,
        imageUrl: p['image_url'] ?? '',
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('خطأ في جلب المنتجات: $e');
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await supabase.from('products').insert({
        'id': product.id,
        'name': product.name,
        'restaurant_name': product.restaurantName,
        'price': product.price,
        'category': product.category,
        'available': product.available,
        'image_url': product.imageUrl,
      });
      fetchProductsFromSupabase();
    } catch (e) {
      debugPrint('خطأ في إضافة المنتج: $e');
    }
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

  void toggleProductAvailability(String id) async {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      final p = products[index];
      final newStatus = !p.available;
      await supabase.from('products').update({'available': newStatus}).eq('id', id);
      fetchProductsFromSupabase();
    }
  }

  List orders = [];
  List chatMessages = [];
  List notifications = [];

  void addNotification(String title, String body) {
    notifications.insert(0, {'title': title, 'body': body, 'time': DateTime.now()});
    notifyListeners();
  }

  void listenToOrdersRealtime() async {
    try {
      final initialData = await supabase.from('orders').select();
      orders = initialData;
      notifyListeners();

      supabase.from('orders').stream(primaryKey: ['id']).listen((data) {
        orders = data;
        notifyListeners();
      }, onError: (error) {
        debugPrint('⚠️ خطأ في الاستماع للطلبات: $error');
      });
    } catch (e) {
      debugPrint('❌ خطأ في الاستماع للطلبات: $e');
    }
  }

  List getMessagesForOrder(String orderId, String targetChat) {
    return chatMessages.where((msg) => msg.orderId == orderId && msg.targetChat == targetChat).toList();
  }

  void sendChatMessage(String orderId, String senderRole, String targetChat, String messageText) {
    if (messageText.trim().isEmpty) return;

    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: orderId,
      senderRole: senderRole,
      targetChat: targetChat,
      message: messageText.trim(),
      timestamp: DateTime.now(),
    );

    chatMessages.add(newMsg);
    notifyListeners();
  }

  Future<void> createOrder({
    required String customerName,
    required String phone,
    required String address,
    required String itemsDesc,
    required double productsTotal,
  }) async {
    userProfile = {'phone': phone, 'name': customerName, 'city': currentCity, 'address': address};
    final orderId = 'TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    try {
      await supabase.from('customers').upsert({
        'phone': phone,
        'name': customerName,
        'city': address,
      }, onConflict: 'phone');
    } catch (e) {
      debugPrint('خطأ في حفظ العميل: $e');
    }

    final orderData = {
      'id': orderId,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'items_description': itemsDesc,
      'products_total': productsTotal,
      'delivery_fee': 0.0,
      'total_price': productsTotal,
      'assigned_courier': 'لم يتم التعيين',
      'status': 'waitingForPricing',
      'is_fee_sent': false,
      'admin_message': 'بانتظار تحديد رسوم التوصيل من المشرف',
      'date': DateTime.now().toString().split(' ')[0],
    };

    try {
      await supabase.from('orders').insert(orderData);
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('خطأ في إنشاء الطلب: $e');
    }
  }

  Future<void> setOrderDeliveryFee(String orderId, double fee, String courierName) async {
    try {
      final order = orders.firstWhere((o) => o['id'].toString() == orderId, orElse: () => null);
      double productsTotal = order != null ? double.tryParse(order['products_total'].toString()) ?? 0.0 : 0.0;
      double totalPrice = productsTotal + fee;

      await supabase.from('orders').update({
        'delivery_fee': fee,
        'total_price': totalPrice,
        'assigned_courier': courierName.trim(),
        'status': 'waitingCourierApproval',
        'is_fee_sent': true,
        'admin_message': 'تم تحديد رسوم التوصيل ($fee ر.ي) وإسناد الطلب للمندوب بنجاح ⏳',
      }).eq('id', orderId);
    } catch (e) {
      debugPrint('خطأ تحديث الرسوم: $e');
    }
  }

  Future<void> customerConfirmOrder(String orderId) async {
    await supabase.from('orders').update({
      'status': 'waitingCourierApproval',
      'admin_message': 'تم تأكيد الطلب من قِبل العميل ⏳',
    }).eq('id', orderId);
  }

  Future<void> customerCancelOrder(String orderId) async {
    await supabase.from('orders').update({
      'status': 'cancelledByCustomer',
      'admin_message': 'تم إلغاء الطلب من قِبل العميل ❌',
    }).eq('id', orderId);
  }

  Future<void> courierRespondToOrder(String orderId, bool accepted) async {
    final order = orders.firstWhere((o) => o['id'].toString() == orderId, orElse: () => null);
    if (order != null) {
      if (accepted) {
        await supabase.from('orders').update({
          'status': 'onTheWay',
          'admin_message': 'المندوب قَبِل الطلب وهو في الطريق 🟢',
        }).eq('id', orderId);
      } else {
        await supabase.from('orders').update({
          'status': 'rejectedByCourier',
          'admin_message': '⚠️ المندوب رَفَض الطلب!',
          'assigned_courier': 'لم يتم التعيين',
          'is_fee_sent': false,
        }).eq('id', orderId);
      }
    }
  }

  Future<void> courierUpdateArrival(String orderId) async {
    await supabase.from('orders').update({
      'status': 'arrived',
      'admin_message': 'المندوب وصل لموقع العميل 📍',
    }).eq('id', orderId);
  }

  Future<void> markOrderDelivered(String orderId) async {
    await supabase.from('orders').update({
      'status': 'delivered',
      'admin_message': 'تم تسليم الطلب بنجاح ✅',
    }).eq('id', orderId);
  }
}
