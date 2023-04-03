// Much of this file was originally sourced from:
// https://github.com/adityathakurxd/webrtc_flutter/blob/main/lib/main.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';
import 'package:screen_streamer/screen_streamer.dart';
import 'package:sdp_transform/sdp_transform.dart';

/// Provides a mechanism to receive a WebRTC screen stream.
class ScreenReceiver {
  static final Logger _logger = Logger('ScreenReceiver');
  final List<Map<String, dynamic>> _candidates = [];
  final Completer<Uri> _uri = Completer<Uri>();

  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer? _remoteVideoRenderer;

  RTCVideoRenderer get remoteVideoRenderer {
    final result = _remoteVideoRenderer;

    if (result == null) {
      throw Exception('''
A request to get the "remoteVideoRenderer" was called before "listen" has
completed.  Please be  sure to wait for "listen" to complete requesting
"remoteVideoRenderer".
''');
    }
    return result;
  }

  /// Returns the URI this is listening on.
  Future<Uri> get uri => _uri.future;

  /// Disconnects from the screen stream.
  Future<void> disconnect() async {
    await _peerConnection?.dispose();
    _peerConnection = null;
    await _remoteVideoRenderer?.dispose();
    _remoteVideoRenderer = null;
  }

  /// Listens for a screen stream.  If an [address] is not provided then this
  /// will attempt to bind to the first IPv4 address that is detected via
  /// [NetworkInterface].
  ///
  /// The [candidateDelay] is the amount of time to wait for the device to
  /// provide an answer to the offer.
  Future<void> listen({
    InternetAddress? address,
    Duration? candidateDelay,
    int port = 5333,
  }) async {
    final list = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );

    address ??= list.first.addresses.first;
    final server = await HttpServer.bind(
      address,
      port,
    );
    _logger.info('Listening on: ${server.address.address}:$port...');
    final uri = Uri.parse('ws://${server.address.address}:$port');
    _uri.complete(uri);

    final req = await server.first;
    final socket = await WebSocketTransformer.upgrade(req);

    Completer? completer = Completer();
    final future = completer.future;

    socket.listen((message) async {
      final data = json.decode(message);
      final offer = WebRtcOffer.fromDynamic(data);

      final answer = await _createAnswer(
        offer,
        candidateDelay: candidateDelay ?? const Duration(milliseconds: 500),
      );

      socket.add(json.encode(answer));
      completer?.complete(null);
      completer = null;
    }).onError((e, stack) {
      completer?.completeError(e, stack);
      completer = null;
    });

    // ignore: unawaited_futures
    socket.done.then((value) => socket.close());

    await future;
  }

  Future<WebRtcAnswer> _createAnswer(
    WebRtcOffer offer, {
    required Duration candidateDelay,
  }) async {
    final pc = await _createPeerConnecion();

    await pc.setRemoteDescription(RTCSessionDescription(
      write(offer.offer, null),
      offer.type,
    ));

    final description = await pc.createAnswer(
      const {'offerToReceiveVideo': 1},
    );
    final session = parse(description.sdp.toString());
    await pc.setLocalDescription(description);

    await Future.delayed(candidateDelay);

    return WebRtcAnswer(
      answer: session,
      candidates: _candidates,
    );
  }

  Future<RTCPeerConnection> _createPeerConnecion() async {
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

      await _remoteVideoRenderer?.dispose();
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      _remoteVideoRenderer = renderer;

      pc.onIceCandidate = (e) {
        if (e.candidate != null) {
          _logger.info('Found candidate: ${e.candidate}');
          _candidates.add({
            'candidate': e.candidate.toString(),
            'sdpMid': e.sdpMid.toString(),
            'sdpMlineIndex': e.sdpMLineIndex,
          });
        }
      };

      pc.onAddStream = (stream) {
        _logger.info('Stream added');
        renderer.srcObject = stream;
      };
      pc.onAddTrack = (stream, track) {
        _logger.info('Track added');
        renderer.srcObject = stream;
      };
      pc.onConnectionState = (state) {
        _logger.info('New connection state: $state');
      };
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
