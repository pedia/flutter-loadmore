import 'dart:async';
import 'package:flutter/material.dart';
import 'listview.dart';
import 'models.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    print('-------------');
    print('global error: $details');
    print('-------------');
  };

  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Loadmore Example"),
          elevation: 0,
        ),
        body: DemoList(provider: Provider()),
      ),
    ),
  );
}
