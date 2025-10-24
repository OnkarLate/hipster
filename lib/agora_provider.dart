import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';


class AgoraProvider extends ChangeNotifier {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  bool _isScreenSharing = false;
  int? _remoteUid;

  RtcEngine? get engine => _engine;
  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isVideoDisabled => _isVideoDisabled;
  bool get isScreenSharing => _isScreenSharing;
  int? get remoteUid => _remoteUid;

  Future<void> initAgora(String appId, String channelName, String? token) async {
    // 1. Request permissions
    await [Permission.microphone, Permission.camera].request();

    // 2. Create engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _isJoined = true;
          notifyListeners();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _remoteUid = remoteUid;
          notifyListeners();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _remoteUid = null;
          notifyListeners();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _isJoined = false;
          _remoteUid = null;
          notifyListeners();
        },
      ),
    );

    // 3. Enable video and join channel
    await _engine!.enableVideo();
    await _engine!.startPreview();
    await _engine!.joinChannel(
      token: token!,
      channelId: channelName,
      uid: 0, // 0 lets Agora assign a UID
      options: const ChannelMediaOptions(),
    );
  }

  // --- Control Methods ---

  void toggleAudio() {
    _isMuted = !_isMuted;
    _engine!.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoDisabled = !_isVideoDisabled;
    _engine!.enableLocalVideo(!_isVideoDisabled);
    notifyListeners();
  }

  // --- [START] CORRECTED METHOD ---
  Future<void> toggleScreenShare() async {
    if (_isScreenSharing) {
      // --- Stop Screen Share ---
      await _engine!.stopScreenCapture();
      // Switch back to camera
      await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
        publishCameraTrack: true,
        publishScreenTrack: false,
      ));
      _isScreenSharing = false;
    } else {
      // --- Start Screen Share ---

      // Define the screen capture parameters.
      // You can adjust dimensions and framerate as needed.
      const ScreenCaptureParameters2 parameters = ScreenCaptureParameters2(
        captureAudio: true, // Capture system audio
        captureVideo: true,
        videoParams: ScreenVideoParameters(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 15,
        ),
      );

      // Pass the parameters to startScreenCapture
      await _engine!.startScreenCapture(parameters);

      // Switch to publishing screen track
      await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
        publishCameraTrack: false, // Turn off camera
        publishScreenTrack: true, // Turn on screen share
        publishMicrophoneTrack: true, // Keep microphone on
      ));
      _isScreenSharing = true;
    }
    notifyListeners();
  }
  // --- [END] CORRECTED METHOD ---

  // --- Cleanup ---

  Future<void> leaveChannel() async {
    if (_engine != null) {
      if (_isScreenSharing) {
        await _engine!.stopScreenCapture();
      }
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }
    _isJoined = false;
    _isScreenSharing = false;
    _remoteUid = null;
  }
}