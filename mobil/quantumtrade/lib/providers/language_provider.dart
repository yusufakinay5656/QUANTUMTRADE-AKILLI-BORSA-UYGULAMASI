import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  bool _isEnglish = false;

  bool get isEnglish => _isEnglish;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('isEnglish') ?? false;
    notifyListeners();
  }

  Future<void> setLanguage(bool isEnglish) async {
    _isEnglish = isEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', isEnglish);
    notifyListeners();
  }

  String getText(String key) {
    if (_isEnglish) {
      return _englishTranslations[key] ?? key;
    }
    return _turkishTranslations[key] ?? key;
  }

  static final Map<String, String> _turkishTranslations = {
    // Genel
    'Ana Sayfa': 'Ana Sayfa',
    'Piyasa': 'Piyasa',
    'Profilim': 'Profilim',
    'Satın Al': 'Satın Al',
    'Ayarlar': 'Ayarlar',
    'Yardım': 'Yardım',
    'Kullanıcı Girişi': 'Kullanıcı Girişi',
    'Giriş Yap': 'Giriş Yap',
    'Kayıt Ol': 'Kayıt Ol',
    'Şifremi Unuttum': 'Şifremi Unuttum',
    'E-posta': 'E-posta',
    'Şifre': 'Şifre',
    'Ad': 'Ad',
    'Soyad': 'Soyad',
    'Yeni Hesap Oluştur': 'Yeni Hesap Oluştur',
    'Şifre Yenileme': 'Şifre Yenileme',
    'Şifremi Yenile': 'Şifremi Yenile',
    'Toplam İşlem': 'Toplam İşlem',
    'Başarılı İşlem': 'Başarılı İşlem',
    'Başarısız İşlem': 'Başarısız İşlem',
    'Satın Alınanlar': 'Satın Alınanlar',
    'Portföy Özeti': 'Portföy Özeti',
    'Portföy Performansı': 'Portföy Performansı',
    'Son İşlemler': 'Son İşlemler',
    'Bitcoin Haberleri': 'Bitcoin Haberleri',
    'Bu dünya sizin': 'Bu dünya sizin',
    'İçindekilerin hepsine sahip olmak istiyorsan': 'İçindekilerin hepsine sahip olmak istiyorsan',
    'quantumtrade ile bir tık uzağınızda': 'quantumtrade ile bir tık uzağınızda',
  };

  static final Map<String, String> _englishTranslations = {
    // General
    'Ana Sayfa': 'Home',
    'Piyasa': 'Market',
    'Profilim': 'Profile',
    'Satın Al': 'Buy',
    'Ayarlar': 'Settings',
    'Yardım': 'Help',
    'Kullanıcı Girişi': 'Login',
    'Giriş Yap': 'Sign In',
    'Kayıt Ol': 'Sign Up',
    'Şifremi Unuttum': 'Forgot Password',
    'E-posta': 'Email',
    'Şifre': 'Password',
    'Ad': 'First Name',
    'Soyad': 'Last Name',
    'Yeni Hesap Oluştur': 'Create New Account',
    'Şifre Yenileme': 'Password Reset',
    'Şifremi Yenile': 'Reset Password',
    'Toplam İşlem': 'Total Transactions',
    'Başarılı İşlem': 'Successful Transactions',
    'Başarısız İşlem': 'Failed Transactions',
    'Satın Alınanlar': 'Purchases',
    'Portföy Özeti': 'Portfolio Summary',
    'Portföy Performansı': 'Portfolio Performance',
    'Son İşlemler': 'Recent Transactions',
    'Bitcoin Haberleri': 'Bitcoin News',
    'Bu dünya sizin': 'This world is yours',
    'İçindekilerin hepsine sahip olmak istiyorsan': 'If you want to own everything in it',
    'quantumtrade ile bir tık uzağınızda': 'quantumtrade is just one click away',
  };
} 