import 'package:flutter/material.dart';
import 'package:hipster/auth_provider.dart';
import 'package:hipster/login_screen.dart';
import 'package:hipster/user_list_screen.dart';
import 'package:hipster/user_model.dart';
import 'package:hipster/user_provider.dart';
import 'package:hipster/video_call_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // 2. --- ADD THIS LINE ---
  // Register the adapter
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
        title: 'Video Call App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(), // Ensure this isn't const if AuthWrapper isn't
      ),
    );
  }
}

// This widget will reactively show Login or Home based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      // 🚨 Change this line to your desired screen 🚨
      // return const UserListScreen();
      return const VideoCallScreen(appId: 'c5b556bdf3e6446b850ee6cf14d17f99',channelName: 'hipster',token: '007eJxTYHB6Km1dGc0vPnHTbqtttXOOzPCLqF1/9MRrrrovYabzt79RYEg2TTI1NUtKSTNONTMxMUuyMDVITTVLTjM0STE0T7O0nB//O6MhkJGhRM6NlZEBAkF8doaMzILiktQiBgYA6EkhnQ==',);
    } else {
      return const LoginScreen();
    }
  }
}