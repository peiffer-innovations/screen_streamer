// Much of this file was originally sourced from:
// https://github.com/adityathakurxd/webrtc_flutter/blob/main/lib/main.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';
import 'package:screen_streamer/screen_streamer.dart';
import 'package:screen_streamer/src/web_rtc/screen_select_dialog.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Class to simplify streaming a device's screen or desktop window using
/// WebRTC.
class ScreenSender {
  final List<Map<String, dynamic>> _candidates = [];
  final Logger _logger = Logger('ScreenSender');

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  /// Connects a screen stream to a remote listener that is listening to the
  /// [uri].
  Future<void> connect(
    Uri uri, {
    required BuildContext context,
  }) async {
    DesktopCapturerSource? source;
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final service = FlutterBackgroundService();
        await service.configure(
          androidConfiguration: AndroidConfiguration(
            onStart: _onStart,

            // auto start service
            autoStart: true,
            isForegroundMode: true,
          ),
          iosConfiguration: IosConfiguration(),
        );
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        source = await showDialog<DesktopCapturerSource>(
          context: context,
          builder: (context) => const ScreenSelectDialog(),
        );
      }
    }

    final offer = await _createOffer(source);

    Completer? completer = Completer();
    final future = completer.future;

    WebSocketChannel? ws = WebSocketChannel.connect(uri);
    try {
      await ws.ready;
      ws.stream.listen((message) async {
        final map = json.decode(message);

        final answer = WebRtcAnswer.fromDynamic(map);
        await _completeConnection(answer);

        await ws?.sink.close();
        ws = null;
        completer?.complete();
        completer = null;
      });

      ws?.sink.add(json.encode(offer.toJson()));

      await future;
    } catch (e, stack) {
      completer?.completeError(e, stack);
      completer = null;
    } finally {
      await ws?.sink.close();
      ws = null;
    }

    await future;
  }

  /// Disconnects the stream.
  Future<void> disconnect() async {
    try {
      if (kIsWeb) {
        _localStream?.getTracks().forEach((track) => track.stop());
      }
      await _localStream?.dispose();
      _localStream = null;
    } catch (e, stack) {
      _logger.severe('Error disconnecting', e, stack);
    }

    await _peerConnection?.dispose();
    _peerConnection = null;
  }

  /// Returns whether or not the current device is supported by the framework.
  /// While all platforms are supported, simulators and emulators are not.
  Future<bool> isSupported() async {
    var supported = false;

    if (kIsWeb) {
      supported = true;
    } else {
      final plugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        supported = info.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        supported = info.isPhysicalDevice;
      } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        supported = true;
      }
    }

    return supported;
  }

  Future<void> _completeConnection(WebRtcAnswer answer) async {
    final pc = _peerConnection!;
    final candidates = answer.candidates;

    await pc.setRemoteDescription(RTCSessionDescription(
      write(answer.answer, null),
      answer.type,
    ));

    for (var session in candidates) {
      final candidate = RTCIceCandidate(
        session['candidate'],
        session['sdpMid'],
        session['sdpMlineIndex'],
      );
      await pc.addCandidate(candidate);
    }
  }

  Future<MediaStream> _createLocalStream(DesktopCapturerSource? source) async {
    final stream = await navigator.mediaDevices.getDisplayMedia(
      <String, dynamic>{
        'video': source == null
            ? true
            : {
                'deviceId': {'exact': source.id},
                'mandatory': {'frameRate': 30.0},
              }
      },
    );

    return stream;
  }

  Future<WebRtcOffer> _createOffer([DesktopCapturerSource? source]) async {
    final pc = await _createPeerConnecion(source);
    final description = await pc.createOffer(
      const {'offerToReceiveVideo': 0},
    );
    final session = parse(description.sdp.toString());
    await pc.setLocalDescription(description);

    return WebRtcOffer(offer: session);
  }

  Future<RTCPeerConnection> _createPeerConnecion(
    DesktopCapturerSource? source,
  ) async {
    try {
      await _peerConnection?.dispose();
      _candidates.clear();

      final pc = await createPeerConnection(
        const {},
        const {
          'mandatory': {
            'OfferToReceiveVideo': true,
          },
          'optional': [],
        },
      );

      final stream = await _createLocalStream(source);
      _localStream = stream;

      final tracks = stream.getVideoTracks();
      for (var track in tracks) {
        _logger.info('Added track');
        await pc.addTrack(track, stream);
      }

      pc.onIceConnectionState = (e) {
        _logger.info('Ice connection state: $e');
      };

      _peerConnection = pc;

      return pc;
    } catch (e, stack) {
      _logger.severe('Error creating peer connection', e, stack);
      rethrow;
    }
  }
}

void _onStart(ServiceInstance service) {}
