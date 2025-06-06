import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          languageProvider.getText('Kayıt Ol'),
          style: TextStyle(
            color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage('assets/images/logo.jpg'),
                ),
              ),
              const SizedBox(height: 40),
              // Kayıt Formu
              Card(
                color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        languageProvider.getText('Yeni Hesap Oluştur'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          labelText: languageProvider.getText('Ad'),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? const Color(0xFF444444) : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: languageProvider.getText('Soyad'),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? const Color(0xFF444444) : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: languageProvider.getText('E-posta'),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? const Color(0xFF444444) : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: languageProvider.getText('Şifre'),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? const Color(0xFF444444) : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Kayıt işlemi
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          languageProvider.getText('Kayıt Ol'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
          border: Border(top: BorderSide(color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black)),
        ),
        child: Text(
          "© 2025 QuantumTrade • Tüm Hakları Saklıdır",
          textAlign: TextAlign.center,
          style: TextStyle(color: themeProvider.isDarkMode ? Colors.grey : Colors.black54),
        ),
      ),
    );
  }
} 