import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart'; // تأكد أن المسار صحيح لملف الـ AppState لديك
import 'screens/terms_screen.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  void setTheme(ThemeMode mode) {
    value = mode;
  }
}

final themeNotifier = ThemeNotifier();

class TaizDeliveryApp extends StatelessWidget {
  const TaizDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // تغليف التطبيق بالكامل بـ MultiProvider لكي تحل مشكلة الـ Provider في أي شاشة
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentThemeMode, child) {
          return MaterialApp(
            title: 'تعز إكسبرس للتوصيل',
            debugShowCheckedModeBanner: false,
            themeMode: currentThemeMode,
            theme: ThemeData(
              primarySwatch: Colors.amber,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.grey[100],
              fontFamily: 'Cairo',
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.amber,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212),
              fontFamily: 'Cairo',
            ),
            home: const TermsScreen(),
          );
        },
      ),
    );
  }
}