import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'user_model.dart';

class UserProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<User> _users = [];
  final String _usersBox = 'usersBox';

  bool get isLoading => _isLoading;
  List<User> get users => _users;

  UserProvider() {
    // Load from cache immediately on startup
    _loadFromCache();
    // Then try to refresh from network
    fetchUsers();
  }

  Future<void> _loadFromCache() async {
    _setLoading(true);
    final box = await Hive.openBox<User>(_usersBox);
    _users = box.values.toList();
    _setLoading(false);
  }

  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      // 1. Try fetching from network
      final response = await http.get(Uri.parse('https://reqres.in/api/users?page=1'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<User> apiUsers = (data['data'] as List)
            .map((userJson) => User.fromJson(userJson))
            .toList();

        // 2. Update cache
        final box = await Hive.openBox<User>(_usersBox);
        await box.clear(); // Clear old data
        await box.addAll(apiUsers); // Add new data

        _users = apiUsers;
      }
    } on SocketException {
      // 3. Offline: If network fails, _loadFromCache already ran.
      // We can just notify listeners that we are done "loading"
      // and are showing cached data.
    } catch (e) {
      // Handle other errors
      print(e);
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}