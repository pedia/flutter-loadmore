import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdrpulm/pdrpulm.dart';

class Tank extends StatefulWidget {
  _TankState createState() => new _TankState();
}

class Indicator extends StatelessWidget {
  Indicator(this.text);

  final String text;

  Widget build(BuildContext context) {
    return new Container(
        height: 20.0,
        alignment: const Alignment(0.0, 0.0),
        child: new Text(text));
  }
}

class _TankState extends State<Tank> {
  int itemCount;

  @override
  initState() {
    super.initState();

    itemCount = 10;
  }

  Future<Null> onLoadMore() {
    final Completer<Null> completer = new Completer<Null>();
    new Timer(const Duration(microseconds: 1), () {
      completer.complete(null);
    });
    return completer.future.then((_) {
      setState(() {
        itemCount += 10;
      });
    });
  }

  Widget build(BuildContext context) {
    return new ScrollIndicator(
        onLoadMore: onLoadMore,
        child: new ListView.builder(
            itemCount: itemCount,
            itemBuilder: (BuildContext context, int index) {
              return new Container(
                height: 150.0,
                decoration: new BoxDecoration(border: new Border.all()),
                child: new Indicator(index.toString()),
              );
            }));
  }
}

void main() => runApp(new MaterialApp(
    home: new Scaffold(
        appBar: new AppBar(title: const Text("EXAMPLE FOR PDRPULM")),
        body: new Tank())));
