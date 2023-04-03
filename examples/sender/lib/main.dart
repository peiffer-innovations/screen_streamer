import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sender',
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
  final TextEditingController _controller = TextEditingController(
    text: 'ws://localhost:5333',
  );
  final ScreenSender _sender = ScreenSender();

  bool _connected = false;
  bool _connecting = false;
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    final storage = const FlutterSecureStorage();
    storage.read(key: 'url').then((value) {
      if (value != null && value.isNotEmpty) {
        _controller.text = value;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Future<void> _connect() async {
    try {
      _connecting = true;
      if (mounted) {
        setState(() {});
      }

      final storage = const FlutterSecureStorage();
      await storage.write(key: 'url', value: _controller.text);

      await _sender.connect(
        Uri.parse(_controller.text),
        context: context,
      );

      _connecting = false;
      _connected = true;
      if (mounted) {
        setState(() {});
      }
    } catch (e, stack) {
      debugPrint('$e');
      debugPrint('$stack');
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
            ],
            content: const Text('Unable to connect'),
            title: const Text('Error'),
          ),
        );
      }
    } finally {
      _connecting = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connected ? 'Connected' : 'Waiting'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!_connected)
              Row(
                children: [
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextFormField(
                      controller: _controller,
                      decoration:
                          const InputDecoration(label: Text('Receiver URL')),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: _connecting ? null : _connect,
                    child: const Text('CONNECT'),
                  ),
                  const SizedBox(width: 16.0),
                ],
              ),
            const SizedBox(height: 16.0),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
