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
    fetchProductsFromSupabase();
    fetchCouriersFromSupabase();
    listenToOrdersRealtime();
  }

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

  // 1. توليد كود التحقق OTP
  void requestOtpForPhone(String phone) {
    final randomOtp = (100000 + Random().nextInt(900000)).toString();
    generatedDynamicOtp = randomOtp;
    notifyListeners();
  }

  // تعيين الكود المولد يدوياً من واجهة الواتساب
  void setCustomGeneratedOtp(String phone, String otp) {
    generatedDynamicOtp = otp;
    notifyListeners();
  }

  // 2. دالة إرسال رسالة الواتساب الحقيقية من سيرفر إلى سيرفر لرقم العميل
  Future<bool> sendOtpViaServerWhatsApp(String recipientPhone) async {
    if (generatedDynamicOtp == null) return false;

    // تنسيق رقم الهاتف بالصيغة الدولية لليمن (967)
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

    // بيانات حساب UltraMsg أو WhatsApp API Gateway الخاص بك
    const instanceId = 'YOUR_INSTANCE_ID'; // استبدل بـ Instance ID الخاص بك
    const token = 'YOUR_API_TOKEN';        // استبدل بـ Token الخاص بك

    final url = Uri.parse('https://api.ultramsg.com/$instanceId/messages/chat');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': token,
          'to': formattedPhone,
          'body': messageText,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['sent'] == 'true' || jsonResponse['status'] == 'success') {
          debugPrint('✅ تم إرسال الرمز لرقم العميل الواتساب بنجاح: $formattedPhone');
          return true;
        }
      }
      debugPrint('❌ فشل إرسال رسالة الواتساب: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('❌ خطأ في الاتصال بسيرفر الواتساب: $e');
      return false;
    }
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

  // دالة حفظ بيانات المستخدم في جدول Supabase مباشرة وضمان عدم تكرار تسجيل الدخول
  Future<void> saveUserProfileDetails(String name, String address) async {
    if (userProfile != null) {
      userProfile!['name'] = name;
      userProfile!['address'] = address;
      
      String phone = userProfile!['phone'] ?? '';

      try {
        // الحفظ الفعلي في جدول customers في Supabase مطابَقاً لأسماء الأعمدة (phone, name, city)
        await supabase.from('customers').upsert({
          'phone': phone,
          'name': name,
          'city': address,
        }, onConflict: 'phone');

        debugPrint('✅ تم حفظ بيانات العميل في قاعدة بيانات Supabase بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في حفظ بيانات العميل في Supabase: $e');
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
      debugPrint('خطأ في إضافة المندوب لقاعدة البيانات: $e');
    }
  }

  bool loginCourier(String username, String password) {
    final index = couriers.indexWhere(
          (c) => c['username'] == username && c['password'] == password,
    );
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

  int get totalCartItemsCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
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
      debugPrint('خطأ في إضافة المنتج لقاعدة البيانات: $e');
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
    notifications.insert(0, {
      'title': title,
      'body': body,
      'time': DateTime.now(),
    });
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
        debugPrint('⚠️ خطأ في الاستماع للطلبات لحظياً: $error');
      });
    } catch (e) {
      debugPrint('❌ خطأ في جلب أو الاستماع للطلبات: $e');
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
    String roleTitle = senderRole == 'admin' ? 'الإدارة' : (senderRole == 'courier' ? 'المندوب' : 'العميل');
    addNotification('💬 رسالة جديدة من $roleTitle (طلب #$orderId)', messageText);
    notifyListeners();
  }

  Future<void> createOrder({
    required String customerName,
    required String phone,
    required String address,
    required String itemsDesc,
    required double productsTotal,
  }) async {
    userProfile = {
      'phone': phone,
      'name': customerName,
      'city': currentCity,
      'address': address,
    };

    final orderId = 'TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    try {
      final customerResponse = await supabase.from('customers').upsert({
        'phone': phone,
        'name': customerName,
        'city': address,
      }, onConflict: 'phone');
      debugPrint('✅ تم حفظ بيانات العميل بنجاح: $customerResponse');
    } catch (e) {
      debugPrint('❌ خطأ دالة حفظ العميل في جدول customers: $e');
      addNotification('⚠️ خطأ في حفظ العميل', 'التفاصيل: $e');
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
      clearCacheAndCart();
      notifyListeners();
      debugPrint('✅ تم إنشاء الطلب #$orderId بنجاح في قاعدة البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
      addNotification('⚠️ خطأ في إنشاء الطلب', 'التفاصيل: $e');
    }
  }

  void clearCacheAndCart() {
    _cartItems.clear();
  }

  Future<void> setOrderDeliveryFee(String orderId, double fee, String courierName) async {
    try {
      final order = orders.firstWhere((o) => o['id'].toString() == orderId, orElse: () => null);
      double productsTotal = 0.0;
      if (order != null) {
        productsTotal = double.tryParse(order['products_total'].toString()) ?? 0.0;
      }
      double totalPrice = productsTotal + fee;

      await supabase.from('orders').update({
        'delivery_fee': fee,
        'total_price': totalPrice,
        'assigned_courier': courierName.trim(),
        'status': 'waitingCourierApproval',
        'is_fee_sent': true,
        'admin_message': 'تم تحديد رسوم التوصيل ($fee ر.ي) وإسناد الطلب للمندوب ($courierName) بنجاح ⏳',
      }).eq('id', orderId);

      addNotification('🔔 تم إسناد الطلب #$orderId للمندوب', 'تم تحديد الرسوم وإرسال الطلب للمندوب $courierName بنجاح.');
      debugPrint('✅ تم تحديث الطلب وإرساله للمندوب: $courierName بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحديث رسوم ومندوب الطلب: $e');
    }
  }

  Future<void> enableOrderFeeEditing(String orderId) async {
    await supabase.from('orders').update({'is_fee_sent': false}).eq('id', orderId);
  }

  Future<void> customerConfirmOrder(String orderId) async {
    await supabase.from('orders').update({
      'status': 'waitingCourierApproval',
      'admin_message': 'تم تأكيد الطلب من قِبل العميل، وبانتظار قبول المندوب ⏳',
    }).eq('id', orderId);

    addNotification('✅ تم تأكيد الطلب #$orderId', 'تم إرسال الطلب للمندوب المعين بانتظار قبوله.');
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
      final courierName = order['assigned_courier'];
      if (accepted) {
        await supabase.from('orders').update({
          'status': 'onTheWay',
          'admin_message': 'المندوب ($courierName) قَبِل الطلب وهو في الطريق الآن 🟢',
        }).eq('id', orderId);
      } else {
        await supabase.from('orders').update({
          'status': 'rejectedByCourier',
          'admin_message': '⚠️ المندوب ($courierName) رَفَض الطلب! يرجى إسناده لمندوب آخر.',
          'assigned_courier': 'لم يتم التعيين',
          'is_fee_sent': false,
        }).eq('id', orderId);
      }
    }
  }

  Future<void> courierUpdateArrival(String orderId) async {
    await supabase.from('orders').update({
      'status': 'arrived',
      'admin_message': 'المندوب وصل لموقع العميل (أبلغ العميل الآن) 📍',
    }).eq('id', orderId);
    addNotification('المندوب وصل!', 'وصل المندوب إلى موقع العميل للطلب #$orderId');
  }

  Future<void> markOrderDelivered(String orderId) async {
    final order = orders.firstWhere((o) => o['id'].toString() == orderId, orElse: () => null);
    if (order != null) {
      await supabase.from('orders').update({
        'status': 'delivered',
        'admin_message': 'تم تسليم الطلب بنجاح للعميل ✅',
      }).eq('id', orderId);

      addNotification('تم تسليم الطلب', 'تم تسليم الطلب #$orderId بنجاح للعميل.');
    }
  }
}
