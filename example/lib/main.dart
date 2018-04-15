import 'package:flutter/material.dart';
import 'stock_list.dart';
import 'stock_data.dart';

class TheApp extends StatelessWidget {
  final StockData data = new StockData();

  Widget build(BuildContext context) {
    return new StockList(
      stockData: data,
      scrollDirection: Axis.vertical,
    );
  }
}

void main() => runApp(
      new MaterialApp(
        home: new Scaffold(
          appBar: new AppBar(
            title: const Text("EXAMPLE FOR PDRPULM"),
            elevation: 0.0,
          ),
          body: new TheApp(),
        ),
      ),
    );
