import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔑 تم إدخال رابط ومفتاح مشروعك في Supabase بنجاح
  await Supabase.initialize(
    url: 'https://pzokmpthkpuofrntufyp.supabase.co',
    anonKey: 'sb_publishable_uI01Ippgs8yXi9k18JO8DQ_Zm74RqQf',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تعز إكسبرس – Taiz Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.amber),
      home: const HomeScreen(),
    );
  }
}