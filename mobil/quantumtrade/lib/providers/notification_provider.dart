import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  List<String> _notifications = [];
  int _unreadCount = 0;

  List<String> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void addNotification(String notification) {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  void markAllAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }
} 