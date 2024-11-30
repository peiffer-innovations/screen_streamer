import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

/// Dialog to select what screen or window to stream.
class ScreenSelectDialog extends Dialog {
  const ScreenSelectDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: _ScreenSelectContainer(),
    );
  }
}

class _ScreenSelectContainer extends StatefulWidget {
  @override
  State createState() => _ScreenSelectContainerState();
}

class _ScreenSelectContainerState extends State<_ScreenSelectContainer> {
  static final Logger _logger = Logger('_ScreenSelectContainerState');

  final Map<String, DesktopCapturerSource> _sources = {};
  final List<StreamSubscription<DesktopCapturerSource>> _subscriptions = [];

  SourceType _sourceType = SourceType.Screen;
  DesktopCapturerSource? _selectedSource;
  StateSetter? _stateSetter;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _subscriptions.add(desktopCapturer.onAdded.stream.listen((source) {
      _sources[source.id] = source;
      _stateSetter?.call(() {});
    }));

    _subscriptions.add(desktopCapturer.onRemoved.stream.listen((source) {
      _sources.remove(source.id);
      _stateSetter?.call(() {});
    }));

    _subscriptions
        .add(desktopCapturer.onThumbnailChanged.stream.listen((source) {
      _stateSetter?.call(() {});
    }));

    Future.delayed(const Duration(milliseconds: 100), _getSources);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var element in _subscriptions) {
      element.cancel();
    }

    _subscriptions.clear();

    super.dispose();
  }

  void _cancel(context) async {
    _timer?.cancel();
    for (var element in _subscriptions) {
      await element.cancel();
    }
    _subscriptions.clear();

    if (mounted) {
      Navigator.pop<DesktopCapturerSource>(context, null);
    }
  }

  Future<void> _getSources() async {
    try {
      final sources = await desktopCapturer.getSources(types: [_sourceType]);
      for (var element in sources) {
        _logger.finer(
          'name: ${element.name}, id: ${element.id}, type: ${element.type}',
        );
      }
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        desktopCapturer.updateSources(types: [_sourceType]);
      });
      _sources.clear();
      for (var element in sources) {
        _sources[element.id] = element;
      }
      _stateSetter?.call(() {});
    } catch (e, stack) {
      _logger.severe(
        'Error getting media sources',
        e,
        stack,
      );
    }
  }

  void _ok(context) async {
    _timer?.cancel();
    for (var element in _subscriptions) {
      await element.cancel();
    }
    Navigator.pop<DesktopCapturerSource>(context, _selectedSource);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 640,
      height: 560,
      color: Colors.white,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              children: <Widget>[
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Choose what to share',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    child: const Icon(Icons.close),
                    onTap: () => _cancel(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: StatefulBuilder(
                builder: (context, setState) {
                  _stateSetter = setState;
                  return DefaultTabController(
                    length: 2,
                    child: Column(
                      children: <Widget>[
                        Container(
                          constraints: const BoxConstraints.expand(height: 24),
                          child: TabBar(
                              onTap: (value) => Future.delayed(
                                      const Duration(milliseconds: 300), () {
                                    _sourceType = value == 0
                                        ? SourceType.Screen
                                        : SourceType.Window;
                                    _getSources();
                                  }),
                              tabs: const [
                                Tab(
                                    child: Text(
                                  'Entire Screen',
                                  style: TextStyle(color: Colors.black54),
                                )),
                                Tab(
                                    child: Text(
                                  'Window',
                                  style: TextStyle(color: Colors.black54),
                                )),
                              ]),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Expanded(
                          child: TabBarView(children: [
                            Align(
                                alignment: Alignment.center,
                                child: GridView.count(
                                  crossAxisSpacing: 8,
                                  crossAxisCount: 2,
                                  children: _sources.entries
                                      .where((element) =>
                                          element.value.type ==
                                          SourceType.Screen)
                                      .map((e) => _ThumbnailWidget(
                                            onTap: (source) {
                                              setState(() {
                                                _selectedSource = source;
                                              });
                                            },
                                            source: e.value,
                                            selected: _selectedSource?.id ==
                                                e.value.id,
                                          ))
                                      .toList(),
                                )),
                            Align(
                                alignment: Alignment.center,
                                child: GridView.count(
                                  crossAxisSpacing: 8,
                                  crossAxisCount: 3,
                                  children: _sources.entries
                                      .where((element) =>
                                          element.value.type ==
                                          SourceType.Window)
                                      .map((e) => _ThumbnailWidget(
                                            onTap: (source) {
                                              setState(() {
                                                _selectedSource = source;
                                              });
                                            },
                                            source: e.value,
                                            selected: _selectedSource?.id ==
                                                e.value.id,
                                          ))
                                      .toList(),
                                )),
                          ]),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OverflowBar(
              children: <Widget>[
                MaterialButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black54),
                  ),
                  onPressed: () {
                    _cancel(context);
                  },
                ),
                MaterialButton(
                  color: Theme.of(context).primaryColor,
                  child: const Text(
                    'Share',
                  ),
                  onPressed: () {
                    _ok(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class _ThumbnailWidget extends StatefulWidget {
  const _ThumbnailWidget({
    required this.onTap,
    required this.selected,
    required this.source,
  });

  final Function(DesktopCapturerSource) onTap;
  final bool selected;
  final DesktopCapturerSource source;

  @override
  _ThumbnailWidgetState createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<_ThumbnailWidget> {
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions.add(widget.source.onThumbnailChanged.stream.listen((event) {
      setState(() {});
    }));
    _subscriptions.add(widget.source.onNameChanged.stream.listen((event) {
      setState(() {});
    }));
  }

  @override
  void deactivate() {
    for (var element in _subscriptions) {
      element.cancel();
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: widget.selected
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  )
                : null,
            child: InkWell(
              onTap: () {
                debugPrint('Selected source id => ${widget.source.id}');
                widget.onTap(widget.source);
              },
              child: widget.source.thumbnail != null
                  ? Image.memory(
                      widget.source.thumbnail!,
                      gaplessPlayback: true,
                      alignment: Alignment.center,
                    )
                  : const SizedBox(),
            ),
          ),
        ),
        Text(
          widget.source.name,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
