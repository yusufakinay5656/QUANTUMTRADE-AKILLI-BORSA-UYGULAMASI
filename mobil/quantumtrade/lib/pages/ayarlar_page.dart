import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar_button.dart';

class AyarlarPage extends StatelessWidget {
  const AyarlarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          languageProvider.getText('Ayarlar'),
          style: TextStyle(
            color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          UserAvatarButton(),
        ],
      ),
      drawer: Drawer(
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                border: Border(bottom: BorderSide(color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/logo.jpg'),
                    radius: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'QuantumTrade',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '"The world is yours"',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Ana Sayfa'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: Icon(Icons.show_chart, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Piyasa'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/piyasa');
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Profilim'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/profilim');
              },
            ),
            ListTile(
              leading: Icon(Icons.smart_toy, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text('AI Analiz', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/ai-analiz');
              },
            ),
            ListTile(
              leading: Icon(Icons.psychology, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text('AI Asistan', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/ai-asistan');
              },
            ),
            Divider(color: themeProvider.isDarkMode ? const Color(0xFF444444) : Colors.grey),
            ListTile(
              leading: Icon(Icons.settings, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Ayarlar'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: true,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Yardım'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/yardim');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Çıkış Yap'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                      title: Text(
                        'Çıkış Yap',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                        ),
                      ),
                      content: Text(
                        'Çıkış yapmak istediğinizden emin misiniz?',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'İptal',
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.blue,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Provider.of<AuthProvider>(context, listen: false).logout();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            'Çıkış Yap',
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tema Ayarları
              Card(
                color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getText('Tema'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(
                          languageProvider.getText('Karanlık Mod'),
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        activeColor: const Color(0xFFFFD700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Dil Ayarları
              Card(
                color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getText('Dil'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          'Türkçe',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        trailing: !languageProvider.isEnglish
                            ? Icon(Icons.check, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black)
                            : null,
                        onTap: () {
                          languageProvider.setLanguage(false);
                        },
                      ),
                      ListTile(
                        title: Text(
                          'English',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        trailing: languageProvider.isEnglish
                            ? Icon(Icons.check, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black)
                            : null,
                        onTap: () {
                          languageProvider.setLanguage(true);
                        },
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