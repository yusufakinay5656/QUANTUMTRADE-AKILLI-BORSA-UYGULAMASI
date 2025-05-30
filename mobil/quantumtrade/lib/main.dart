import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/auth_provider.dart';
import 'pages/home_page.dart';
import 'pages/piyasa_page.dart';
import 'pages/profilim_page.dart';
import 'pages/ai_assistant_page.dart';
import 'pages/ayarlar_page.dart';
import 'pages/yardim_page.dart';
import 'pages/giris_page.dart';
import 'pages/registration_step1_page.dart';
import 'pages/registration_step2_page.dart';
import 'pages/register_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'QuantumTrade',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF111111),
                foregroundColor: Color(0xFFFFD700),
              ),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return authProvider.isAuthenticated ? const HomePage() : const GirisPage();
                    },
                  ),
              '/piyasa': (context) => Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return authProvider.isAuthenticated ? const PiyasaPage() : const GirisPage();
                    },
                  ),
              '/profilim': (context) => Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return authProvider.isAuthenticated ? const ProfilimPage() : const GirisPage();
                    },
                  ),
              '/ai-analiz': (context) => Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return authProvider.isAuthenticated ? const AIAssistantPage() : const GirisPage();
                    },
                  ),
              '/ai-asistan': (context) => Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return authProvider.isAuthenticated ? const AIAssistantPage() : const GirisPage();
                    },
                  ),
              '/ayarlar': (context) => Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return authProvider.isAuthenticated ? const AyarlarPage() : const GirisPage();
                    },
                  ),
              '/yardim': (context) => Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return authProvider.isAuthenticated ? const YardimPage() : const GirisPage();
                    },
                  ),
              '/giris': (context) => const GirisPage(),
              '/login': (context) => const GirisPage(),
              '/register': (context) => const RegisterPage(),
              '/registerStep1': (context) => const RegistrationStep1Page(),
              '/registerStep2': (context) => RegistrationStep2Page(userData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
            },
          );
        },
      ),
    );
  }
}
