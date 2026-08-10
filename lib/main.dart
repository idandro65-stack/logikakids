import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_config.dart';
import 'data/datasources/local_store.dart';
import 'data/datasources/supabase_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Offline Store (Hive) & Supabase Cloud Client
  await LocalStore.instance.init();
  await SupabaseService.instance.init();

  runApp(const LogikaKidsApp());
}

class LogikaKidsApp extends StatelessWidget {
  const LogikaKidsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF43F5E),
          primary: const Color(0xFFF43F5E),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFFAF9F9),
      ),
      home: LocalStore.instance.currentUser != null
          ? const MainNavigationScreen()
          : const LoginScreen(),
    );
  }
}
