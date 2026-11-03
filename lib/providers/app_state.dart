import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
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
    fetchStoreSettings();
    fetchProductsFromSupabase();
    fetchCouriersFromSupabase();
    listenToOrdersRealtime();
    listenToStoreSettingsRealtime();
  }

  // --- إعدادات أوقات الدوام والدعم ---
  int startHour = 8;
  int endHour = 24;
  String customerSupportPhone = '770000000'; // رقم الدعم الفني العام

  bool isDarkMode = true;
  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  // --- إدارة رسائل الشات ودعم الطلبات (مصححة متوافقة تماماً مع chat_screen.dart) ---
  List getMessagesForOrder(String orderId, String targetChat) {
    return chatMessages.where((msg) => msg['order_id'].toString() == orderId.toString() && msg['target_chat'] == targetChat).toList();
  }

  Future<void> sendChatMessage(String orderId, String senderRole, String targetChat, String message) async {
    try {
      final newMessage = {
        'order_id': orderId,
        'sender_role': senderRole,
        'target_chat': targetChat,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // إضافة الرسالة محلياً لتظهر فوراً
      chatMessages.add(newMessage);
      notifyListeners();

      // محاولة حفظها في Supabase إن وجد الجدول، أو الاكتفاء بالتحديث المحلي
      try {
        await supabase.from('chat_messages').insert(newMessage);
      } catch (e) {
        debugPrint('⚠️ ملاحظة حول جدول الشات في سوبابيس: $e');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال رسالة الشات: $e');
    }
  }

  String currentCity = 'تعز';
  void setCity(String city) {
    currentCity = city;
    if (userProfile != null) {
      userProfile!['city'] = city;
    }
    notifyListeners();
  }

  // --- 1. إرسال رمز التحقق عبر الواتساب المباشر wa.me ---
  Future<void> sendOtpViaWhatsAppDirect(String phone) async {
    if (generatedDynamicOtp == null) return;

    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '967${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('967')) {
      formattedPhone = '967$formattedPhone';
    }

    final message = Uri.encodeComponent(
      '🌟 تطبيق FAST - تعز 🌟\nرمز التحقق الخاص بك هو: *$generatedDynamicOtp*'
    );

    final whatsappUrl = Uri.parse("https://wa.me/$formattedPhone?text=$message");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ خطأ في فتح تطبيق الواتساب: $e');
    }
  }

  // --- 2. مشاركة التطبيق باستخدام نافذة مشاركة النظام الرسمية ---
  void shareApp() {
    Share.share(
      'حمل تطبيق FAST - أسرع خدمة توصيل في تعز! 🚀\nhttps://play.google.com/store/apps/details?id=com.fast.taiz',
      subject: 'تطبيق FAST تعز',
    );
  }

  // --- طلب الأذونات والموقع ---
  Future<void> requestLocationAndNotificationPermissions() async {
    try {
      debugPrint('📍 تم طلب إذن الوصول إلى الموقع الجغرافي والإشعارات بنجاح');
      addNotification('تطبيق FAST - تعز', 'تم تفعيل الإشعارات وتحديد الموقع بنجاح 🚀');
    } catch (e) {
      debugPrint('❌ خطأ في طلب الأذونات: $e');
    }
  }

  // --- جلب واستماع إعدادات المتجر ---
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

  Future<void> updateStoreSettings(int start, int end) async {
    startHour = start;
    endHour = end;
    notifyListeners();

    try {
      await supabase.from('settings').upsert({
        'id': 1,
        'start_hour': start,
        'end_hour': end,
      });
      debugPrint('✅ تم تحديث أوقات الدوام بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ أوقات الدوام: $e');
    }
  }

  bool get isStoreOpen {
    final now = DateTime.now();
    final currentHour = now.hour;
    if (endHour > startHour) {
      return currentHour >= startHour && currentHour < endHour;
    } else {
      return currentHour >= startHour || currentHour < endHour;
    }
  }

  // --- جلسة المشرف ---
  bool isAdminLoggedIn = false;

  void _loadAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    isAdminLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
    notifyListeners();
  }

  bool loginAdmin(String password) {
    if (password == 'admin1234') { // كلمة سر لوحة التحكم
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

  // --- مصادقة المستخدم والـ OTP ---
  Map<String, String>? userProfile;
  String? generatedDynamicOtp;

  void requestOtpForPhone(String phone) {
    final randomOtp = (100000 + Random().nextInt(900000)).toString();
    generatedDynamicOtp = randomOtp;
    notifyListeners();
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
        }, onConflict: 'phone');

        await requestLocationAndNotificationPermissions();
        debugPrint('✅ تم حفظ بيانات العميل بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في حفظ العميل: $e');
      }

      notifyListeners();
    }
  }

  void logoutUser() {
    userProfile = null;
    notifyListeners();
  }

  // --- إدارة المناديب والمزامنة مع Supabase ---
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
      debugPrint('❌ خطأ في جلب المناديب من Supabase: $e');
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
      await fetchCouriersFromSupabase();
      debugPrint('✅ تم إدخال المندوب في Supabase بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المندوب: $e');
    }
  }

  bool loginCourier(String username, String password) {
    final index = couriers.indexWhere((c) => c['username'].toString().trim() == username.trim() && c['password'].toString().trim() == password.trim());
    if (index != -1) {
      couriers[index]['is_logged_in'] = true;
      currentCourier = couriers[index];

      final cId = currentCourier!['id']?.toString() ?? currentCourier!['delivery_man_id'].toString();
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('loggedCourierId', cId);
      });

      try {
        supabase.from('couriers').update({'is_logged_in': true}).eq('id', cId);
      } catch (e) {
        debugPrint('⚠️ خطأ تحديث حالة المندوب: $e');
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  void logoutCourier() {
    if (currentCourier != null) {
      final courierId = currentCourier!['id'] ?? currentCourier!['delivery_man_id'];
      final index = couriers.indexWhere((c) => c['delivery_man_id'] == courierId || c['id'] == courierId);
      if (index != -1) {
        couriers[index]['is_logged_in'] = false;
      }

      try {
        supabase.from('couriers').update({'is_logged_in': false}).eq('id', courierId);
      } catch (e) {
        debugPrint('⚠️ خطأ تحديث خروج المندوب: $e');
      }

      currentCourier = null;
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('loggedCourierId');
      });
      notifyListeners();
    }
  }

  // --- سلة المشتريات ---
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

  // --- إدارة المنتجات والربط مع Supabase ---
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
      debugPrint('❌ خطأ في جلب المنتجات: $e');
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await supabase.from('products').insert({
        'name': product.name,
        'restaurant_name': product.restaurantName,
        'price': product.price,
        'category': product.category,
        'available': product.available,
        'image_url': product.imageUrl,
      });
      await fetchProductsFromSupabase();
      debugPrint('✅ تم إضافة المنتج بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المنتج: $e');
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

  // --- إدارة الطلبات المباشرة والمزامنة ---
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
      debugPrint('❌ خطأ في جلب الطلبات: $e');
    }
  }

  Future<void> createOrder({
    required String customerName,
    required String phone,
    required String address,
    required String itemsDesc,
    required double productsTotal,
  }) async {
    userProfile = {'phone': phone, 'name': customerName, 'city': currentCity, 'address': address};

    final orderData = {
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
      addNotification('تم إنشاء الطلب بنجاح', 'طلبك بانتظار تحديد السعر ⏳');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
    }
  }

  Future<void> setOrderDeliveryFee(dynamic orderId, double fee, String courierName) async {
    try {
      final order = orders.firstWhere((o) => o['id'].toString() == orderId.toString(), orElse: () => null);
      double productsTotal = order != null ? double.tryParse(order['products_total'].toString()) ?? 0.0 : 0.0;
      double totalPrice = productsTotal + fee;

      await supabase.from('orders').update({
        'delivery_fee': fee,
        'total_price': totalPrice,
        'assigned_courier': courierName.trim(),
        'status': 'pricingSentToCustomer',
        'is_fee_sent': true,
        'admin_message': 'تم تحديد رسوم التوصيل ($fee ر.ي) وإسناد الطلب للمندوب بنجاح ⏳',
      }).eq('id', orderId);

      addNotification('تحديث الطلب #$orderId', 'تم تحديد رسوم التوصيل ($fee ر.ي). يرجى تأكيد الطلب! 🔔');
    } catch (e) {
      debugPrint('❌ خطأ تحديث الرسوم: $e');
    }
  }

  Future<void> customerConfirmOrder(dynamic orderId) async {
    await supabase.from('orders').update({
      'status': 'waitingCourierApproval',
      'admin_message': 'تم تأكيد الطلب من قِبل العميل ⏳',
    }).eq('id', orderId);
  }

  Future<void> customerCancelOrder(dynamic orderId) async {
    await supabase.from('orders').update({
      'status': 'cancelledByCustomer',
      'admin_message': 'تم إلغاء الطلب من قِبل العميل ❌',
    }).eq('id', orderId);
  }

  Future<void> courierRespondToOrder(dynamic orderId, bool accepted) async {
    if (accepted) {
      await supabase.from('orders').update({
        'status': 'onTheWay',
        'admin_message': 'المندوب قَبِل الطلب وهو في الطريق 🟢',
      }).eq('id', orderId);
      addNotification('طلبك في الطريق!', 'المندوب في طريقه إليك الآن 🛵');
    } else {
      await supabase.from('orders').update({
        'status': 'rejectedByCourier',
        'admin_message': '⚠️ المندوب رَفَض الطلب!',
        'assigned_courier': 'لم يتم التعيين',
        'is_fee_sent': false,
      }).eq('id', orderId);
    }
  }

  Future<void> courierUpdateArrival(dynamic orderId) async {
    await supabase.from('orders').update({
      'status': 'arrived',
      'admin_message': 'المندوب وصل لموقع العميل 📍',
    }).eq('id', orderId);
    addNotification('وصول المندوب', 'المندوب وصل إلى موقعك الآن! 📍');
  }

  Future<void> markOrderDelivered(dynamic orderId) async {
    await supabase.from('orders').update({
      'status': 'delivered',
      'admin_message': 'تم تسليم الطلب بنجاح ✅',
    }).eq('id', orderId);
    addNotification('تم التسليم', 'شكراً لاستخدامك FAST! تم تسليم طلبك بنجاح ✅');
  }
}
