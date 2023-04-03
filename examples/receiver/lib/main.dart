import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:screen_streamer/screen_streamer.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      // ignore: avoid_print
      print('${record.error}');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('${record.stackTrace}');
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receiver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScreenReceiver _receiver = ScreenReceiver();

  bool _connected = false;

  @override
  void initState() {
    super.initState();

    _receiver.listen().then(((value) {
      _connected = true;
      if (mounted) {
        setState(() {});
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connected ? 'Connected' : 'Waiting'),
      ),
      body: _connected
          ? RemoteScreenRenderer(receiver: _receiver)
          : Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const CircularProgressIndicator(),
                  FutureBuilder(
                    builder: (context, snapshot) => snapshot.hasData
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(snapshot.data.toString()),
                          )
                        : const SizedBox(),
                    future: _receiver.uri,
                  ),
                ],
              ),
            ),
    );
  }
}
