import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'app_drawer.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _shellScaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
    _shellScaffoldKey.currentState?.closeDrawer();
  }

  void _openDrawer() => _shellScaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<AppState, int>((state) => state.cartItemCount);
    return Scaffold(
      key: _shellScaffoldKey,
      drawer: AppDrawer(onNavigate: _navigateTo),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onOpenDrawer: _openDrawer),
          CartScreen(onOpenDrawer: _openDrawer),
          OrdersScreen(onOpenDrawer: _openDrawer),
          ProfileScreen(onOpenDrawer: _openDrawer),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.storefront), label: 'الرئيسية'),
          NavigationDestination(
            icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart)),
            label: 'السلة',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long), label: 'طلباتي'),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}
