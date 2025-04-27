import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';          // Ana Sayfa
import 'pages/piyasa_page.dart';         // Piyasa Sayfası
import 'pages/profilim_page.dart';       // Profilim Sayfası
import 'pages/satin_al_page.dart';       // Satın Al Sayfası
import 'pages/login_page.dart';          // Giriş Sayfası
import 'pages/register_page.dart';       // Kayıt Sayfası
import 'pages/forgot_password_page.dart'; // Şifre Kurtarma Sayfası
import 'pages/ayarlar_page.dart';        // Ayarlar Sayfası
import 'pages/yardim_page.dart';         // Yardım Sayfası
import 'pages/page_transition.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notification_provider.dart';
import 'pages/notifications_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'QuantumTrade',
      theme: themeProvider.theme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return PageTransition(
              page: const HomePage(),
              direction: AxisDirection.right,
            );
          case '/piyasa':
            return PageTransition(
              page: const PiyasaPage(),
              direction: AxisDirection.right,
            );
          case '/profilim':
            return PageTransition(
              page: const ProfilimPage(),
              direction: AxisDirection.right,
            );
          case '/satin-al':
            return PageTransition(
              page: const SatinAlPage(),
              direction: AxisDirection.right,
            );
          case '/login':
            return PageTransition(
              page: const LoginPage(),
              direction: AxisDirection.up,
            );
          case '/register':
            return PageTransition(
              page: const RegisterPage(),
              direction: AxisDirection.up,
            );
          case '/forgot-password':
            return PageTransition(
              page: const ForgotPasswordPage(),
              direction: AxisDirection.up,
            );
          case '/ayarlar':
            return PageTransition(
              page: const AyarlarPage(),
              direction: AxisDirection.right,
            );
          case '/yardim':
            return PageTransition(
              page: const YardimPage(),
              direction: AxisDirection.right,
            );
          case '/notifications':
            return PageTransition(
              page: const NotificationsPage(),
              direction: AxisDirection.right,
            );
          default:
            return PageTransition(
              page: const HomePage(),
              direction: AxisDirection.right,
            );
        }
      },
    );
  }
}
