import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  bool _isPasswordVisible = false;

  bool get isPasswordVisible => _isPasswordVisible;

  void toggleVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);

    await Future.delayed(const Duration(seconds: 1));

    if (email == "omkarlate97@gmail.com" && password == "12345678") {
      _isAuthenticated = true;
      _setLoading(false);
    } else {
      _setLoading(false);
      throw Exception('Invalid email or password');
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}