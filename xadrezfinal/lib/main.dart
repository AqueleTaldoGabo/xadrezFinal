import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'service/auth_service.dart';
import 'view/auth_page.dart';
import 'view/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  static const green = Color(0xFF81B64C);
  static const background = Color(0xFF312E2B);
  static const panel = Color(0xFF262421);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess.com App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: panel,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(color: panel),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: green),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: StreamBuilder(
        stream: AuthService().authState,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashPage();
          }
          return snapshot.hasData ? const HomePage() : const AuthPage();
        },
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChessApp.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/chess_icon.png', width: 112, height: 112),
            const SizedBox(height: 18),
            const Text(
              'Chess.com App',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 22),
            const CircularProgressIndicator(color: ChessApp.green),
          ],
        ),
      ),
    );
  }
}
