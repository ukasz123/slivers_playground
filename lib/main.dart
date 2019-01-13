import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:slivers_playground/sliver_diagnostic.dart';

List<Color> colorsSet = [
  Colors.brown,
  Colors.green,
  Colors.yellow,
  Colors.pink,
  Colors.cyan,
  Colors.red,
  Colors.brown.shade200,
  Colors.green.shade200,
  Colors.yellow.shade200,
  Colors.pink.shade400,
  Colors.cyan.shade200,
  Colors.red.shade300,
  Colors.brown.shade700,
  Colors.green.shade700,
  Colors.yellow.shade700,
  Colors.pink.shade700,
  Colors.cyan.shade700,
  Colors.red.shade700,
];

Color _pickColor(int index) => colorsSet[index % colorsSet.length];

String _formatDouble(double value) => value.toStringAsFixed(2);

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: SafeArea(child: SliversPlayground()),
      ),
    );
  }
}

class SliversPlayground extends StatefulWidget {
  @override
  _SliversPlaygroundState createState() => _SliversPlaygroundState();
}

class _IndexedMetadata extends SliverMetadata {
  final int index;

  _IndexedMetadata(
      {Map<String, double> constraintsData,
      Map<String, double> geometryData,
      this.index})
      : super(constraintsData, geometryData);
}

class _SliversPlaygroundState extends State<SliversPlayground> {
  StreamController<_IndexedMetadata> _sliversData;
  int sliversCount = 8;

  Stream<_IndexedMetadata> _sliversDataStream;

  Map<int, Map<String, double>> _current = {};

  StreamSubscription<_IndexedMetadata> _sub;

  @override
  void initState() {
    super.initState();
    _sliversData = StreamController();
    _sliversDataStream = _sliversData.stream.asBroadcastStream();
    _sub = _sliversDataStream.listen((data) {
      _current[data.index] = data.constraintsData;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sliversData?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 150,
            maxHeight: 200,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                  sliversCount, (i) => _buildInfoPanel(context, i)).toList(),
            ),
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: List.generate(sliversCount, (i) => i)
                .map((i) => _buildSliverListItem(context, i))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(BuildContext context, int index) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              "Index: $index",
              style: Theme.of(context)
                  .textTheme
                  .subtitle
                  .copyWith(color: _pickColor(index)),
            ),
            Divider(
              height: 6.0,
              color: Colors.greenAccent.shade700,
            ),
            Row(
              children: [
                StreamBuilder<Map<String, double>>(
                  initialData: _current[index],
                  stream: _sliversDataStream
                      .where((meta) => meta.index == index)
                      .map((meta) => meta.constraintsData),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data == null) {
                        return Container();
                      }
                      return Column(
                        children: snapshot.data.keys
                            .map(
                              (key) => Text(
                                  "$key: ${_formatDouble(snapshot.data[key])}"),
                            )
                            .toList(),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                SizedBox(
                  width: 4.0,
                ),
                StreamBuilder<Map<String, double>>(
                  initialData: {},
                  stream: _sliversDataStream
                      .where((meta) => meta.index == index)
                      .map((meta) => meta.geometryData),
                  builder: (context, snapshot) {
                    return Column(
                      children: snapshot.data.keys
                          .map(
                            (key) => Text(
                                "$key: ${_formatDouble(snapshot.data[key])}"),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverListItem(BuildContext context, int i) {
    return SliverDiagnostic(
      onDiagnosticData: (data) {
        _sliversData.sink.add(_IndexedMetadata(
            index: i,
            constraintsData: data.constraintsData,
            geometryData: data.geometryData));
      },
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          height: 100.0,
          child: Container(
            color: _pickColor(i),
            child: Center(child: Text("Index: $i")),
          ),
        ),
      ),
    );
  }
}
