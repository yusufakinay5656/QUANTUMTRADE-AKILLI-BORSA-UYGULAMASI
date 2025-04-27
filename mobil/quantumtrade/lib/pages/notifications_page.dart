import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          languageProvider.getText('Bildirimler'),
          style: TextStyle(
            color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (notificationProvider.notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              onPressed: () {
                notificationProvider.clearNotifications();
              },
            ),
        ],
      ),
      body: notificationProvider.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    languageProvider.getText('Bildirim Yok'),
                    style: TextStyle(
                      fontSize: 18,
                      color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeProvider.isDarkMode ? const Color(0xFF444444) : Colors.grey),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications,
                        color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          notificationProvider.notifications[index],
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
} 