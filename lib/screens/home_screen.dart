import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../widgets/fast_app_logo.dart';
import 'admin_screen.dart';
import 'customer/checkout_screen.dart';
import 'auth/phone_auth_screen.dart';
import 'courier_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String selectedCategory = 'الكل';
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _customItemNameController = TextEditingController();
  final TextEditingController _customItemPriceController = TextEditingController();

  final Set<String> _shownPricingDialogs = {};

  @override
  void dispose() {
    _searchController.dispose();
    _customItemNameController.dispose();
    _customItemPriceController.dispose();
    super.dispose();
  }

  void showExitConfirmationDialog(BuildContext context, Color cardBg, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.amber.withOpacity(0.3)),
          ),
          title: Row(
            children: const [
              Icon(Icons.exit_to_app, color: Colors.amber),
              SizedBox(width: 10),
              Text('تأكيد الخروج', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'هل أنت متأكد أنك تريد الخروج من تطبيق FAST؟',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('نعم', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _checkAndShowPricingDialog(BuildContext context, AppState appState, Color cardBg, Color textColor) {
    if (appState.userProfile == null || appState.isAdminLoggedIn) return;

    final customerPhone = appState.userProfile!['phone'];
    for (var order in appState.orders) {
      if (order['phone'] == customerPhone &&
          order['status'] == 'pricingSentToCustomer' &&
          !_shownPricingDialogs.contains(order['id'])) {

        _shownPricingDialogs.add(order['id'].toString());

        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: cardBg,
                title: Row(
                  children: const [
                    Icon(Icons.notifications_active, color: Colors.amber),
                    SizedBox(width: 10),
                    Text('تسعيرة جديدة من المشرف', style: TextStyle(color: Colors.amber, fontSize: 16)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب #${order['id']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('• رسوم التوصيل: (${order['delivery_fee']} ر.ي)', style: TextStyle(color: textColor, fontSize: 14)),
                    Text('• الإجمالي الكلي: ${order['total_price']} ر.ي', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Text('هل توافق على رسوم التوصيل وتأكيد الطلب ليرسل للمندوب؟', style: TextStyle(color: textColor, fontSize: 13)),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      appState.customerConfirmOrder(order['id']);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تأكيد الطلب وإرساله للمندوب بنجاح! ✅')),
                      );
                    },
                    child: const Text('موافقة وتأكيد الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    onPressed: () {
                      appState.customerCancelOrder(order['id']);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم رفض الطلب وإلغاؤه ❌')),
                      );
                    },
                    child: const Text('رفض وإلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // تفعيل الألوان الديناميكية للوضع الفاتح والداكن
    final themeBg = appState.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardBg = appState.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = appState.isDarkMode ? Colors.white : Colors.black87;

    _checkAndShowPricingDialog(context, appState, cardBg, textColor);

    final List<Widget> pages = [
      _buildShopTab(appState, cardBg, textColor),
      _buildCartTab(appState, cardBg, textColor),
      _buildOrdersTab(appState, cardBg, textColor),
      _buildProfileTab(appState, cardBg, textColor),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        showExitConfirmationDialog(context, cardBg, textColor);
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: themeBg,
          appBar: AppBar(
            backgroundColor: cardBg,
            title: Row(
              children: [
                const SizedBox(
                  width: 35,
                  height: 35,
                  child: FittedBox(
                    child: FastAppLogo(),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'FAST – تعز',
                  style: TextStyle(color: Colors.amber[700], fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.two_wheeler, color: Colors.amber),
                tooltip: 'لوحة المندوب',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CourierScreen()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
                tooltip: 'لوحة المشرف',
                onPressed: () {
                  if (appState.isAdminLoggedIn) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
                  } else {
                    final passwordController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: cardBg,
                        title: Text('تسجيل دخول المشرف', style: TextStyle(color: textColor, fontSize: 14)),
                        content: TextField(
                          controller: passwordController,
                          obscureText: true,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'أدخل كلمة السر الخاصة بك',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              bool loginSuccess = appState.loginAdmin(passwordController.text.trim());
                              if (loginSuccess) {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
                              } else {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('كلمة السر غير صحيحة!')),
                                );
                              }
                            },
                            child: const Text('دخول', style: TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 1 && appState.userProfile == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhoneAuthScreen(
                      onLoginSuccess: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 1);
                      },
                    ),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يجب تسجيل الدخول برقم الهاتف للوصول إلى السلة')),
                );
                return;
              }
              setState(() => _currentIndex = index);
            },
            backgroundColor: cardBg,
            selectedItemColor: Colors.amber,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (appState.totalCartItemsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${appState.totalCartItemsCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'السلة',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'طلباتي'),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopTab(AppState appState, Color cardBg, Color textColor) {
    if (selectedCategory == 'طلبات أخرى') {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoriesBar(appState, textColor, cardBg),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('طلب خاص أو خدمة أخرى (مثل: غاز، قات، طلبات من السوق...)', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _customItemNameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'اكتب تفاصيل أو اسم الطلب',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: appState.isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customItemPriceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'السعر التقديري (ر.ي)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: appState.isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () {
                      if (_customItemNameController.text.isNotEmpty && _customItemPriceController.text.isNotEmpty) {
                        final price = double.tryParse(_customItemPriceController.text) ?? 1000.0;
                        appState.addCustomOrderToCart(
                          customName: _customItemNameController.text,
                          estimatedPrice: price,
                        );
                        _customItemNameController.clear();
                        _customItemPriceController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تمت إضافة الطلب الخاص إلى السلة بنجاح!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الرجاء إدخال اسم الطلب والسعر التقديري')),
                        );
                      }
                    },
                    child: const Text('إضافة الطلب الخاص للسلة وتجميعه', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredProducts = (appState.products as List).map((e) => e as ProductModel).where((p) {
      final matchesCategory = selectedCategory == 'الكل' || p.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery) ||
          p.restaurantName.toLowerCase().contains(searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return RefreshIndicator(
      color: Colors.amber,
      backgroundColor: cardBg,
      onRefresh: () async {
        await appState.fetchStoreSettings();
        await appState.fetchProductsFromSupabase();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: cardBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  appState.isStoreOpen ? Icons.check_circle : Icons.access_time_filled,
                  color: appState.isStoreOpen ? Colors.greenAccent : Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  appState.isStoreOpen
                      ? '🟢 نحن مفتوحون الآن (الدوام من ${appState.startHour}:00 ص إلى ${appState.endHour}:00 م)'
                      : '🔴 التطبيق مغلق حالياً (يبدأ الدوام الساعة ${appState.startHour}:00 صباحاً)',
                  style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'ابحث عن طعام، هدايا، خضار، أو دواء...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
          _buildCategoriesBar(appState, textColor, cardBg),
          const SizedBox(height: 10),
          filteredProducts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(50.0),
                  child: Center(child: Text('لا توجد نتائج مطابقة للبحث', style: TextStyle(color: Colors.grey))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final ProductModel product = filteredProducts[index];
                    if (!product.available) return const SizedBox.shrink();

                    int qtyInCart = appState.getProductQuantityInCart(product.id);

                    return Card(
                      color: cardBg,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(product.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${product.restaurantName} - ${product.price} ر.ي / (${product.category})',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        trailing: qtyInCart == 0
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: appState.isStoreOpen
                                    ? () {
                                        appState.addToCart(CartItemModel(
                                          id: product.id,
                                          name: product.name,
                                          price: product.price,
                                          quantity: 1,
                                          restaurantId: product.restaurantName,
                                          imageUrl: product.imageUrl,
                                        ));
                                      }
                                    : null,
                                child: const Text('إضافة للسلة', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.amber, size: 20),
                                    onPressed: () => appState.updateQuantity(product.id, -1),
                                  ),
                                  Text('$qtyInCart', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 20),
                                    onPressed: () => appState.updateQuantity(product.id, 1),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildCategoriesBar(AppState appState, Color textColor, Color cardBg) {
    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: ['الكل', 'المطاعم', 'البقالات', 'الخضار والفواكه', 'الصيدلية الآمنة', 'هدايا واكسسوارات', 'طلبات أخرى'].map((cat) {
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ChoiceChip(
              label: Text(cat, style: TextStyle(color: isSelected ? Colors.black : textColor, fontWeight: FontWeight.bold)),
              selected: isSelected,
              selectedColor: Colors.amber,
              backgroundColor: cardBg,
              onSelected: (val) => setState(() => selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCartTab(AppState appState, Color cardBg, Color textColor) {
    if (appState.userProfile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 60, color: Colors.amber),
              const SizedBox(height: 15),
              Text('يجب تسجيل الدخول للوصول إلى السلة ومتابعة طلباتك', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(200, 45)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhoneAuthScreen(
                        onLoginSuccess: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                child: const Text('تسجيل الدخول برقم الهاتف', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('سلة المشتريات والطلبات المجمعة', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: appState.cartItems.isEmpty
                ? const Center(child: Text('السلة فارغة حالياً', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: appState.cartItems.length,
              itemBuilder: (context, index) {
                final CartItemModel item = appState.cartItems[index];
                return Card(
                  color: cardBg,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(item.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text('السعر: ${item.price} ر.ي | الكمية: ${item.quantity} | الإجمالي: ${item.price * item.quantity} ر.ي', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => appState.removeFromCart(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (appState.cartItems.isNotEmpty) ...[
            const Divider(color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إجمالي السلة المجمعة:', style: TextStyle(color: textColor)),
                Text('${appState.totalAmount} ر.ي', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 45)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                );
              },
              child: Text('الانتقال لتأكيد الطلب المجمع (${appState.totalAmount} ر.ي)', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  String _getArabicStatus(String status) {
    switch (status) {
      case 'waitingForPricing':
        return '⏳ بانتظار تحديد السعر من الإدارة';
      case 'pricingSentToCustomer':
        return '🔔 تم إرسال التسعيرة - بانتظار موافقتك';
      case 'waitingCourierApproval':
        return '🛵 بانتظار قبول المندوب للطلب';
      case 'onTheWay':
        return '🟢 المندوب في الطريق إليك';
      case 'arrived':
        return '📍 وصل المندوب إلى موقعك';
      case 'delivered':
        return '✅ تم تسليم الطلب بنجاح';
      case 'cancelledByCustomer':
        return '❌ تم إلغاء الطلب';
      default:
        return status;
    }
  }

  Widget _buildOrdersTab(AppState appState, Color cardBg, Color textColor) {
    if (appState.orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات سابقة', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appState.orders.length,
      itemBuilder: (context, index) {
        final order = appState.orders[index];
        final arabicStatus = _getArabicStatus(order['status'] ?? '');

        return Card(
          color: cardBg,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('طلب #${order['id']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.amber),
                      tooltip: 'مراسلة الإدارة ودعم الطلب',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              orderId: order['id'].toString(),
                              userRole: 'customer',
                              targetChat: 'admin_customer',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Text('الحالة: $arabicStatus', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 5),
                Text('العنوان: ${order['address']}', style: TextStyle(color: textColor, fontSize: 13)),
                Text('المنتجات: ${order['items_description']}', style: TextStyle(color: textColor, fontSize: 13)),
                Text('سعر المنتجات: ${order['products_total']} ر.ي', style: TextStyle(color: textColor, fontSize: 13)),
                Text('رسوم التوصيل: ${order['delivery_fee']} ر.ي', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                Text('الإجمالي الكلي: ${order['total_price']} ر.ي', style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('المندوب: ${order['assigned_courier']}', style: TextStyle(color: textColor, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(AppState appState, Color cardBg, Color textColor) {
    final profile = appState.userProfile;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Text('حسابي الشخصي', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        profile == null
            ? Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.person, size: 50, color: Colors.amber),
              const SizedBox(height: 10),
              Text('أنت لست مسجل دخول!', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              const Text('سجل دخولك برقم هاتفك للاستمتاع بتجربة التوصيل الأسرع في تعز.', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
                  );
                },
                child: const Text('تسجيل الدخول برقم الهاتف', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        )
            : Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.person, color: Colors.black),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile['name'] ?? 'عميل FAST', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text('📞 ${profile['phone']} | 📍 تعز', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (profile['address'] != null && profile['address'].toString().isNotEmpty)
                      Text('🏠 العنوان: ${profile['address']}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => appState.logoutUser(),
                child: const Text('خروج', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildProfileItem(Icons.dark_mode, 'مظهر التطبيق (${appState.isDarkMode ? "الوضع الداكن" : "الوضع الفاتح"})', cardBg, textColor, () {
          appState.toggleTheme();
        }),
        _buildProfileItem(Icons.location_city, 'المدينة (تعز - اليمن - حصرياً)', cardBg, textColor, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تطبيق FAST مخصص لخدمة مدينة تعز بكل سرعة 🌟')),
          );
        }),
        _buildProfileItem(Icons.bookmark_added, 'عناويني ومواقع التوصيل المحفوظة', cardBg, textColor, () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardBg,
              title: Text('العناوين المحفوظة', style: TextStyle(color: textColor)),
              content: Text(
                profile != null && profile['address'] != null && profile['address'].toString().isNotEmpty
                    ? 'العنوان النشط حالياً:\n${profile['address']}'
                    : 'لم تقم بحفظ عناوين إضافية بعد.',
                style: const TextStyle(color: Colors.grey),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً', style: TextStyle(color: Colors.amber)))
              ],
            ),
          );
        }),
        _buildProfileItem(Icons.local_offer, 'العروض والخصومات الخاصة', cardBg, textColor, () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardBg,
              title: Text('العروض الترويجية', style: TextStyle(color: textColor)),
              content: const Text('ترقبوا أقوى خصومات التوصيل ومجانيات المطاعم قريباً في تعز مع FAST! 🎁', style: TextStyle(color: Colors.grey)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق', style: TextStyle(color: Colors.amber)))
              ],
            ),
          );
        }),
        // 4. مشاركة التطبيق باستخدام Share Plus لنظام التشغيل
        _buildProfileItem(Icons.share, 'مشاركة التطبيق مع الأصدقاء', cardBg, textColor, () {
          appState.shareApp();
        }),
        _buildProfileItem(Icons.help_outline, 'مركز المساعدة والأسئلة الشائعة', cardBg, textColor, () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardBg,
              title: Text('كيف نعمل؟', style: TextStyle(color: textColor)),
              content: const Text(
                '1. تختار منتجاتك أو تطلب طلباً خاصاً.\n2. تحدد الإدارة سعر التوصيل.\n3. توافق على التسعير ليذهب الطلب للمندوب.\n4. يستلم طلبك حتى باب منزلك بكل سرعة!',
                style: TextStyle(color: Colors.grey),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('فهمت', style: TextStyle(color: Colors.amber)))
              ],
            ),
          );
        }),
        // 3. إزالة الرقم الشخصي واستبداله برقم الدعم العام الموحد
        _buildProfileItem(Icons.phone, 'اتصل بخدمة العملاء والدعم', cardBg, textColor, () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardBg,
              title: Text('خدمة العملاء', style: TextStyle(color: textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: Text('رقم الدعم الفني: ${appState.customerSupportPhone}', style: TextStyle(color: textColor)),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق', style: TextStyle(color: Colors.amber)))
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title, Color cardBg, Color textColor, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.amber),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
