import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hipster/feature/model/user_model.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class UserProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<User> _users = [];
  final String _usersBox = 'usersBox';

  bool get isLoading => _isLoading;

  List<User> get users => _users;

  UserProvider() {
    init();
  }

  Future<void> init() async {
    if (await _hasInternetConnection()) {
      debugPrint("Internet available — fetching from API");
      await fetchUsers();
    } else {
      debugPrint("No internet — showing cached data");
      await _loadFromCache();
    }
  }

  // Check internet connection using connectivity_plus
  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    return true;
  }

  //  Load data from local Hive cache
  Future<void> _loadFromCache() async {
    _setLoading(true);
    final box = await Hive.openBox<User>(_usersBox);
    _users = box.values.toList();
    _setLoading(false);
    debugPrint("Loaded ${_users.length} users from cache");
  }

  //  Fetch users from API and update cache
  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      final response = await http.get(Uri.parse('https://reqres.in/api/users'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<User> apiUsers =
            (data['data'] as List)
                .map((userJson) => User.fromJson(userJson))
                .toList();

        // Save to cache
        final box = await Hive.openBox<User>(_usersBox);
        await box.clear();
        await box.addAll(apiUsers);

        _users = apiUsers;
        debugPrint("Users fetched from API and cached");
      } else {
        debugPrint("API error ${response.statusCode} — loading from cache");
        await _loadFromCache();
      }
    } on SocketException {
      debugPrint("Network error — loading from cache");
      await _loadFromCache();
    } catch (e) {
      debugPrint("Error fetching users: $e");
      await _loadFromCache();
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
