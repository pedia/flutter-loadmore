// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdrpulm/pdrpulm.dart';

import 'stock_data.dart';
import 'stock_row.dart';

class StockList extends StatefulWidget {
  const StockList({
    Key key,
    this.stockData,
    this.onOpen,
    this.onShow,
    this.onAction,
    this.scrollDirection,
  }) : super(key: key);

  final StockData stockData;
  final Axis scrollDirection;
  final StockRowActionCallback onOpen;
  final StockRowActionCallback onShow;
  final StockRowActionCallback onAction;

  createState() => new _StockListState();
}

class _StockListState extends State<StockList> {
  @override
  void initState() {
    super.initState();
    if (widget.stockData.stocks.isEmpty) {
      widget.stockData.fetchNextChunk().then((page) {
        setState(() {});
      });
    }
  }

  Future<List<Stock>> _handleLoadMore() {
    return widget.stockData.fetchNextChunk().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return new ScrollIndicator(
      onLoadMore: _handleLoadMore,
      child: new ListView.builder(
        key: const ValueKey<String>('stock-list'),
        scrollDirection: widget.scrollDirection,
        itemExtent: StockRow.kHeight,
        itemCount: widget.stockData.stocks.length,
        itemBuilder: (BuildContext context, int index) {
          return new StockRow(
            stock: widget.stockData.stocks[index],
            onPressed: widget.onOpen,
            onDoubleTap: widget.onShow,
            onLongPressed: widget.onAction,
          );
        },
      ),
    );
  }
}
