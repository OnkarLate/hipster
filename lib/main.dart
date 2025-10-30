import 'package:flutter/material.dart';
import 'package:hipster/feature/provider/auth_provider.dart';
import 'package:hipster/feature/screen/login_screen.dart';
import 'package:hipster/feature/screen/user_list_screen.dart';
import 'package:hipster/feature/model/user_model.dart';
import 'package:hipster/feature/provider/user_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Hipster task',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home:
            const AuthWrapper(), // Ensure this isn't const if AuthWrapper isn't
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return UserListScreen();
      // return const VideoCallScreen(appId: 'c5b556bdf3e6446b850ee6cf14d17f99',channelName: 'hipster',token: '007eJxTYFA4e0lls/XBVQ/9L35d9LJqNnub+GOxt53d+qzRfn+7cpcpMCSbJpmamiWlpBmnmpmYmCVZmBqkppolpxmapBiap1laTljLmNkQyMgwo5SfhZEBAkF8doaMzILiktQiBgYAJY0hoA==',);
    } else {
      return const LoginScreen();
    }
  }
}
