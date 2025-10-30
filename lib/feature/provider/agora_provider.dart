import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraProvider extends ChangeNotifier {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  bool _isScreenSharing = false;
  bool _permissionDenied = false;
  int? _remoteUid;

  RtcEngine? get engine => _engine;
  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isVideoDisabled => _isVideoDisabled;
  bool get isScreenSharing => _isScreenSharing;
  bool get permissionDenied => _permissionDenied;
  int? get remoteUid => _remoteUid;

  Future<void> initAgora(
      String appId,
      String channelName,
      String? token,
      ) async {

    final statuses = await [Permission.microphone, Permission.camera].request();

    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final camGranted = statuses[Permission.camera]?.isGranted ?? false;

    if (!micGranted || !camGranted) {
      _permissionDenied = true;
      notifyListeners();
      return;
    }

    _permissionDenied = false;

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
        onUserOffline:
            (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
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

    await _engine!.enableVideo();
    await _engine!.startPreview();

    await _engine!.joinChannel(
      token: token!,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  void toggleAudio() {
    if (_engine == null) return;
    _isMuted = !_isMuted;
    _engine!.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  void toggleVideo() {
    if (_engine == null) return;
    _isVideoDisabled = !_isVideoDisabled;
    _engine!.enableLocalVideo(!_isVideoDisabled);
    notifyListeners();
  }

  Future<void> toggleScreenShare() async {
    if (_engine == null) return;

    if (_isScreenSharing) {
      await _engine!.stopScreenCapture();
      await _engine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: true,
          publishScreenTrack: false,
          publishScreenCaptureVideo: false,
        ),
      );
      _isScreenSharing = false;
    } else {
      const ScreenCaptureParameters2 parameters = ScreenCaptureParameters2(
        captureAudio: true,
        captureVideo: true,
        videoParams: ScreenVideoParameters(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 15,
        ),
      );

      await _engine!.startScreenCapture(parameters);
      await _engine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: false,
          publishScreenTrack: true,
          publishScreenCaptureVideo: true,
          publishMicrophoneTrack: false,
        ),
      );
      _isScreenSharing = true;
    }
    notifyListeners();
  }

  Future<void> leaveChannel() async {
    if (_engine != null) {
      try {
        if (_isScreenSharing) {
          await _engine!.stopScreenCapture();
        }
        await _engine!.leaveChannel();
        await _engine!.stopPreview();
        await _engine!.release();
      } catch (e) {
        debugPrint("Error releasing Agora Engine: $e");
      } finally {
        _engine = null;
      }
    }

    _isJoined = false;
    _isScreenSharing = false;
    _remoteUid = null;
    notifyListeners();
  }
}
