import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final usuarioId = prefs.getInt('usuarioId');
  final temaEscuro = prefs.getBool('temaEscuro') ?? false;

  temaNotifier.value = temaEscuro ? ThemeMode.dark : ThemeMode.light;

  runApp(
    FinanMasApp(
      logado: usuarioId != null,
    ),
  );
}

class FinanMasApp extends StatelessWidget {
  final bool logado;

  const FinanMasApp({
    super.key,
    required this.logado,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaNotifier,
      builder: (context, modo, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: modo,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF155E63),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F7F8),
            useMaterial3: true,
            fontFamily: 'Arial',
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFFE8ECEF),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B8A83),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF111827),
            useMaterial3: true,
            fontFamily: 'Arial',
            cardTheme: CardThemeData(
              color: const Color(0xFF1F2937),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ),
          home: logado ? const DashboardPage() : const LoginPage(),
        );
      },
    );
  }
}
