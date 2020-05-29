// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_loadmore/loadmore.dart';

import 'models.dart';

class DemoList extends StatefulWidget {
  const DemoList({
    Key key,
    this.provider,
  }) : super(key: key);

  final Provider provider;

  createState() => _DemoListState();
}

class _DemoListState extends State<DemoList> {
  // @override
  // void initState() {
  //   super.initState();
  //   if (widget.stockData.stocks.isEmpty) {
  //     widget.stockData.fetchNextChunk().then((page) {
  //       setState(() {});
  //     });
  //   }
  // }

  Future<List<Demo>> _handleLoadMore() {
    return widget.provider.fetchNextChunk().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.provider.data.isEmpty) {
      Future<List<Demo>> future = widget.provider.fetchNextChunk();
      return FutureBuilder<List<Demo>>(
        future: future,
        builder: (BuildContext context, AsyncSnapshot<List<Demo>> snapshot) {
          // normally ConnectionState : waiting -> done
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.active:
              return Center(child: CupertinoActivityIndicator());
            case ConnectionState.done:
            case ConnectionState.none:
              return createView(context);
            default:
              return Center(
                child: Text("State: ${snapshot.connectionState}"),
              );
          }
        },
      );
    }
    return createView(context);
  }

  Widget createView(BuildContext context) {
    return LoadMore(
      onLoadMore: _handleLoadMore,
      child: ListView.builder(
        itemCount: widget.provider.data.length,
        itemBuilder: (BuildContext context, int index) {
          final item = widget.provider.data[index];
          return ListTile(
            title: Text(item.name),
            leading: CircleAvatar(
              child: Text(
                item.ticker,
                style: Theme.of(context)
                    .textTheme
                    .caption
                    .apply(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
