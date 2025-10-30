import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:hipster/feature/provider/agora_provider.dart';
import 'package:provider/provider.dart';

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
  late final AgoraProvider _agoraProvider;

  @override
  void initState() {
    super.initState();
    _agoraProvider = AgoraProvider();
    _agoraProvider.initAgora(widget.appId, widget.channelName, widget.token);
  }

  @override
  void dispose() {
    _agoraProvider.leaveChannel();
    _agoraProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _agoraProvider.leaveChannel();
        return true; // allow navigation
      },
      child: ChangeNotifierProvider.value(
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
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
            );
          },
        ),
      ),
    );
  }

  Widget _buildRemoteVideo(AgoraProvider provider) {
    if (provider.permissionDenied) {
      return const Center(
        child: Text(
          "Camera or Microphone permission denied.\nPlease enable them from setting to start the call.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    if (provider.engine == null || !provider.isJoined) {
      return const Center(
        child: Text(".......", style: TextStyle(color: Colors.red)),
      );
    }

    if (provider.remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: provider.engine!,
          canvas: VideoCanvas(uid: provider.remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Center(
        child: Text(
          "Waiting for remote user...",
          style: TextStyle(color: Colors.green),
        ),
      );
    }
  }

  Widget _buildLocalVideo(AgoraProvider provider) {
    if (provider.isJoined &&
        provider.engine != null &&
        !provider.isScreenSharing) {
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
            icon: Icon(
              provider.isMuted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
            onPressed: provider.toggleAudio,
          ),
          // Hang Up
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () async {
              await provider.leaveChannel();
              if (context.mounted) {
                Navigator.of(context).pop(); // Go back safely
              }
            },
          ),
          // Disable Video
          IconButton(
            icon: Icon(
              provider.isVideoDisabled ? Icons.videocam_off : Icons.videocam,
              color: Colors.white,
            ),
            onPressed: provider.toggleVideo,
          ),
          // Screen Share
          IconButton(
            icon: Icon(
              provider.isScreenSharing
                  ? Icons.stop_screen_share
                  : Icons.screen_share,
              color: Colors.white,
            ),
            onPressed: provider.toggleScreenShare,
          ),
        ],
      ),
    );
  }
}
