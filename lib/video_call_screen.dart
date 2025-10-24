import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'agora_provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String appId;
  final String channelName;
  final String? token;

  const VideoCallScreen({
    super.key,
    required this.appId,
    required this.channelName,
    this.token,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // Create the provider instance
  late final AgoraProvider _agoraProvider;

  @override
  void initState() {
    super.initState();
    // Initialize the provider and start the connection
    _agoraProvider = AgoraProvider();
    _agoraProvider.initAgora(
      widget.appId,
      widget.channelName,
      widget.token,
    );
  }

  @override
  void dispose() {
    // Crucial: Clean up the engine and provider
    _agoraProvider.leaveChannel();
    _agoraProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide the AgoraProvider to the widget tree below
    return ChangeNotifierProvider.value(
      value: _agoraProvider,
      child: Consumer<AgoraProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            body: Stack(
              children: [
                _buildRemoteVideo(provider),
                _buildLocalVideo(provider),
              ],
            ),
            floatingActionButton: _buildControls(context, provider),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  // --- UI Widgets ---

  Widget _buildRemoteVideo(AgoraProvider provider) {
    if (provider.remoteUid != null && provider.engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: provider.engine!,
          canvas: VideoCanvas(uid: provider.remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Center(
        child: Text(
          provider.isJoined ? 'Waiting for remote user...' : 'Joining channel...',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _buildLocalVideo(AgoraProvider provider) {
    if (provider.isJoined && provider.engine != null && !provider.isScreenSharing) {
      return Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 120,
          height: 180,
          margin: const EdgeInsets.all(16),
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: provider.engine!,
              canvas: const VideoCanvas(uid: 0), // 0 for local user
            ),
          ),
        ),
      );
    }
    // Don't show local view if we are screen sharing (it would show our own screen)
    return const SizedBox.shrink();
  }

  Widget _buildControls(BuildContext context, AgoraProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mute Audio
          IconButton(
            icon: Icon(provider.isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
            onPressed: provider.toggleAudio,
          ),
          // Hang Up
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // Disable Video
          IconButton(
            icon: Icon(provider.isVideoDisabled ? Icons.videocam_off : Icons.videocam, color: Colors.white),
            onPressed: provider.toggleVideo,
          ),
          // Screen Share
          IconButton(
            icon: Icon(provider.isScreenSharing ? Icons.stop_screen_share : Icons.screen_share, color: Colors.white),
            onPressed: provider.toggleScreenShare,
          ),
        ],
      ),
    );
  }
}