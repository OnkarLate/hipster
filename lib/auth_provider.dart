import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    _setLoading(true);

    // 1. Mock API call
    await Future.delayed(const Duration(seconds: 1));

    // 2. Mock Authentication Logic (using ReqRes.in login)
    // Hardcoded: "eve.holt@reqres.in", "cityslicka"
    // Or simpler:
    if (email == "test@test.com" && password == "password") {
      _isAuthenticated = true;
      _setLoading(false);
    } else {
      _setLoading(false);
      // Let the UI know about the failure
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