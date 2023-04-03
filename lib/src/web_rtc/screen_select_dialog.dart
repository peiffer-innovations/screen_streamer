// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ThumbnailWidget extends StatefulWidget {
  const ThumbnailWidget({
    Key? key,
    required this.onTap,
    required this.selected,
    required this.source,
  }) : super(key: key);

  final Function(DesktopCapturerSource) onTap;
  final bool selected;
  final DesktopCapturerSource source;

  @override
  _ThumbnailWidgetState createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
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
    _subscriptions.forEach((element) {
      element.cancel();
    });
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
                  : SizedBox(),
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

// ignore: must_be_immutable
class ScreenSelectDialog extends Dialog {
  ScreenSelectDialog() {
    Future.delayed(Duration(milliseconds: 100), _getSources);

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
  }

  final Map<String, DesktopCapturerSource> _sources = {};
  final List<StreamSubscription<DesktopCapturerSource>> _subscriptions = [];

  SourceType _sourceType = SourceType.Screen;
  DesktopCapturerSource? _selectedSource;
  StateSetter? _stateSetter;
  Timer? _timer;

  void _cancel(context) async {
    _timer?.cancel();
    _subscriptions.forEach((element) {
      element.cancel();
    });
    Navigator.pop<DesktopCapturerSource>(context, null);
  }

  Future<void> _getSources() async {
    try {
      final sources = await desktopCapturer.getSources(types: [_sourceType]);
      sources.forEach((element) {
        debugPrint(
          'name: ${element.name}, id: ${element.id}, type: ${element.type}',
        );
      });
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 3), (timer) {
        desktopCapturer.updateSources(types: [_sourceType]);
      });
      _sources.clear();
      sources.forEach((element) {
        _sources[element.id] = element;
      });
      _stateSetter?.call(() {});
      return;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _ok(context) async {
    _timer?.cancel();
    _subscriptions.forEach((element) {
      element.cancel();
    });
    Navigator.pop<DesktopCapturerSource>(context, _selectedSource);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
          child: Container(
        width: 640,
        height: 560,
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10),
              child: Stack(
                children: <Widget>[
                  Align(
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
                      child: Icon(Icons.close),
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
                padding: EdgeInsets.all(10),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    _stateSetter = setState;
                    return DefaultTabController(
                      length: 2,
                      child: Column(
                        children: <Widget>[
                          Container(
                            constraints: BoxConstraints.expand(height: 24),
                            child: TabBar(
                                onTap: (value) => Future.delayed(
                                        Duration(milliseconds: 300), () {
                                      _sourceType = value == 0
                                          ? SourceType.Screen
                                          : SourceType.Window;
                                      _getSources();
                                    }),
                                tabs: [
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
                          SizedBox(
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
                                        .map((e) => ThumbnailWidget(
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
                                        .map((e) => ThumbnailWidget(
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
            Container(
              width: double.infinity,
              child: ButtonBar(
                children: <Widget>[
                  MaterialButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black54),
                    ),
                    onPressed: () {
                      _cancel(context);
                    },
                  ),
                  MaterialButton(
                    color: Theme.of(context).primaryColor,
                    child: Text(
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
      )),
    );
  }
}
