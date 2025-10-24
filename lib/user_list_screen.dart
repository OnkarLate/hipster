import 'package:flutter/material.dart';
import 'package:hipster/video_call_screen.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use context.watch to rebuild when the user list changes
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Use context.read to call the fetch method
              context.read<UserProvider>().fetchUsers();
            },
          ),
        ],
      ),
      body: userProvider.isLoading && userProvider.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: userProvider.users.length,
        itemBuilder: (context, index) {
          final user = userProvider.users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user.avatar),
            ),
            title: Text('${user.firstName} ${user.lastName}'),
            subtitle: Text(user.email),
            onTap: () {
              // Navigate to Video Call Screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const VideoCallScreen(
                    // Pass hardcoded values for demo
                    appId: "YOUR_AGORA_APP_ID",
                    channelName: "test_channel",
                    token: "YOUR_AGORA_TOKEN", // Or null for testing
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}