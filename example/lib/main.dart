import 'package:flutter/material.dart';
// import 'dart:core';

void main() => runApp(new MaterialApp(home: new Scaffold(body: new Tank())));

enum _PullIndicatorMode { drag, armed, done, canceled }

class Tank extends StatefulWidget {
  _TankState createState() => new _TankState();
}

class _TankState extends State<Tank> {
  double _dragOffset;
  _PullIndicatorMode _mode;

  void changeMode(_PullIndicatorMode mode) {
    print("changeMode: $mode");
    setState(() {
      _mode = mode;
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _dragOffset = 0.0;
      _mode = _PullIndicatorMode.drag;
    }
    if (notification is ScrollUpdateNotification) {
      _dragOffset -= notification.scrollDelta;
      List<String> ls = ["ScrollUpdate"];
      ls.add("[${notification.metrics.extentBefore.toStringAsFixed(1)}");
      ls.add("${notification.metrics.pixels.toStringAsFixed(1)}");
      ls.add("${notification.metrics.extentAfter.toStringAsFixed(1)}]");
      ls.add("${notification.metrics.viewportDimension.toStringAsFixed(1)}");
      ls.add("${notification.scrollDelta.toStringAsFixed(1)}");
      ls.add("total: ${_dragOffset.toStringAsFixed(1)}");
      print(ls.join(" "));

      // notification.metrics.pixels

      if (_mode == _PullIndicatorMode.drag) {
        if (notification.metrics.extentBefore == 0.0 && _dragOffset > 40.0) {
          changeMode(_PullIndicatorMode.armed);
        }
        if (notification.metrics.extentAfter == 0.0 && _dragOffset < -40.0) {
          changeMode(_PullIndicatorMode.armed);
        }
      }
    }
    if (notification is ScrollEndNotification) {
      print("End: ${_dragOffset.toStringAsFixed(1)}");
      _dragOffset = null;
      changeMode(null);
    }
    return false;
  }

  Widget build(BuildContext context) {
    bool flag = _dragOffset != null ?? _dragOffset < 0;
    print("build $_mode, $_dragOffset flag: $flag");
    Widget child = new NotificationListener(
        onNotification: _handleScrollNotification,
        child: new ListView(
            // physics: const AlwaysScrollableScrollPhysics(),
            children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map((String item) {
          return new Container(
            height: 150.0,
            decoration: new BoxDecoration(border: new Border.all()),
            child: new Text(item, textDirection: TextDirection.ltr),
          );
        }).toList()));

    List<Widget> cols = <Widget>[child];
    if (_mode == _PullIndicatorMode.armed && _dragOffset > 0.0) {
      cols.add(new Positioned(
          left: 0.0,
          right: 0.0,
          top: 0.0,
          bottom: null,
          child: new Container(
              // color: Colors.red,
              decoration: new BoxDecoration(border: new Border.all()),
              child: new Text("Refresh..."))));
    }

    if (_mode == _PullIndicatorMode.armed && _dragOffset < 0.0) {
      print("size.height: ${MediaQuery.of(context).size.height}");
      cols.add(new Positioned(
          left: 0.0,
          right: 0.0,
          // top: MediaQuery.of(context).size.height - 40.0,
          // bottom: MediaQuery.of(context).size.height,
          top: 600.0,
          bottom: 640.0,
          child: new Container(
              height: 40.0,
              color: Colors.red,
              child: new Text("Loading more"))));
    }

    return new Scaffold(
        appBar: new AppBar(title: const Text("title")),
        body: new Stack(children: cols));
  }
}
