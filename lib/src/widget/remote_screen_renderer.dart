import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:screen_streamer/screen_streamer.dart';

class RemoteScreenRenderer extends StatefulWidget {
  RemoteScreenRenderer({
    super.key,
    required this.receiver,
  });

  final ScreenReceiver receiver;

  @override
  _RemoteScreenRendererState createState() => _RemoteScreenRendererState();
}

class _RemoteScreenRendererState extends State<RemoteScreenRenderer> {
  @override
  void dispose() {
    widget.receiver.disconnect();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RTCVideoView(widget.receiver.remoteVideoRenderer);
  }
}
