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

  int startHour = 8;
  int endHour = 24;
  String customerSupportPhone = '770000000'; // رقم افتراضي لخدمة العملاء (يمكن تعديله)

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

  // 1. فتح الواتساب المباشر عبر wa.me لترخيص الدخول
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
      debugPrint('❌ خطأ في فتح الواتساب: $e');
    }
  }

  // 4. مشاركة التطبيق بنظام المشاركة المدمج بالجهاز
  void shareApp() {
    Share.share(
      'حمل تطبيق FAST - أسرع خدمة توصيل في تعز! 🚀\nhttps://play.google.com/store/apps/details?id=com.fast.taiz',
      subject: 'تطبيق FAST تعز',
    );
  }

  // جلب إعدادات الدوام من جدول settings
  Future<void> fetchStoreSettings() async {
    try {
      final response = await supabase.from('settings').select().maybeSingle();
      if (response != null) {
        startHour = int.tryParse(response['start_hour'].toString()) ?? 8;
        endHour = int.tryParse(response['end_hour'].toString()) ?? 24;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في جلب إعدادات الدوام: $e');
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
      debugPrint('⚠️ خطأ في الاستماع للإعدادات: $e');
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

  bool isAdminLoggedIn = false;

  void _loadAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    isAdminLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
    notifyListeners();
  }

  bool loginAdmin(String password) {
    if (password == 'admin1234') { // كلمة سر المشرف
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

  // 5. جلب المناديب بمطابقة جدول couriers في Supabase
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

  // 5. جلب المنتجات بحسب حقول جدول products في Supabase
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

  // 5. إضافة منتج جديد بمطابقة أعمدة جدول products
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
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المنتج لـ Supabase: $e');
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

  List orders = [];

  // 5. الاستماع للطلبات مع مطابقة أسماء حقول جدول orders
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

  // 5. إنشاء طلب جديد بحسب حقول جدول orders
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
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
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
}
