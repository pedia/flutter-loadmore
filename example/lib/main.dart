import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdrpulm/pdrpulm.dart';

class Demo extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: const Text("Demo"), elevation: 0.0),
        body: new Center(child: new Text("Demo")));
  }
}

class TheList extends StatefulWidget {
  TheList({
    this.scrollDirection: Axis.vertical,
  });

  final Axis scrollDirection;
  _TheListState createState() => new _TheListState();
}

class _TheListState extends State<TheList> {
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
          scrollDirection: widget.scrollDirection,
          itemCount: itemCount,
          itemBuilder: (BuildContext context, int index) {
            return new InkWell(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  new MaterialPageRoute<Null>(builder: (BuildContext context) {
                    return new Material(
                        child: new Scaffold(
                      appBar: new AppBar(title: new Text("")),
                      body: new TheApp(),
                    ));
                  }),
                );
              },
              child: new Ink(
                height:
                    widget.scrollDirection == Axis.horizontal ? null : 100.0,
                width: widget.scrollDirection == Axis.horizontal ? 50.0 : null,
                decoration: new BoxDecoration(
                  color: Colors.red,
                  border: new Border.all()),
                child: new Center(
                  child: new Text("$index"),
                ),
              ),
            );
          }),
    );
  }
}

class TheApp extends StatelessWidget {
  Widget build(BuildContext context) {
    // return new TheList(
    //   scrollDirection: Axis.vertical,
    // );
    return new Column(
      children: <Widget>[
        new Container(
          height: 100.0,
          child: new TheList(
            scrollDirection: Axis.horizontal,
          ),
        ),
        new Container(
          height: MediaQuery.of(context).size.height - 200,
          child: new TheList(
            scrollDirection: Axis.vertical,
          ),
        ),
      ],
    );
  }
}

void main() => runApp(
      new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(
              title: const Text("EXAMPLE FOR PDRPULM"), elevation: 0.0),
          body: new TheApp(),
        ),
      ),
    );
