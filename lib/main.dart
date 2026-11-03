import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // يمكنك استبدال البيانات أدناه برابط ومفتاح مشروعك في Supabase إذا لزم الأمر
  // try {
  //   await Supabase.initialize(
  //     url: 'YOUR_SUPABASE_URL',
  //     anonKey: 'YOUR_SUPABASE_ANON_KEY',
  //   );
  // } catch (e) {
  //   debugPrint('خطأ في تهيئة Supabase: $e');
  // }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const FastApp(),
    ),
  );
}

class FastApp extends StatelessWidget {
  const FastApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'FAST – تعز',
      debugShowCheckedModeBanner: false,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        primaryColor: Colors.amber,
        colorScheme: const ColorScheme.light(
          primary: Colors.amber,
          secondary: Colors.amber,
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // أسود داكن لكل التطبيق
        primaryColor: Colors.amber,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amber,
          surface: Color(0xFF1E1E1E), // أسود رمادي للكروت
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.amber,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
