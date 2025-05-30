import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  List<String> _notifications = [];
  bool _hasUnreadNotifications = false;

  List<String> get notifications => _notifications;
  bool get hasUnreadNotifications => _hasUnreadNotifications;

  void addNotification(String notification) {
    _notifications.insert(0, notification);
    _hasUnreadNotifications = true;
    notifyListeners();
  }

  void markAllAsRead() {
    _hasUnreadNotifications = false;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _hasUnreadNotifications = false;
    notifyListeners();
  }
} 