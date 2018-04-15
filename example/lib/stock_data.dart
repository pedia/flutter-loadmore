// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Snapshot from http://www.nasdaq.com/screening/company-list.aspx
// Fetched 2/23/2014.
// "Symbol","Name","LastSale","MarketCap","IPOyear","Sector","industry","Summary Quote",
// Data in stock_data.json

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

final math.Random _rng = new math.Random();

class Stock {
  String symbol;
  String name;
  double lastSale;
  String marketCap;
  double percentChange;

  Stock(
    this.symbol,
    this.name,
    this.lastSale,
    this.marketCap,
    this.percentChange,
  );

  Stock.fromFields(List<String> fields) {
    lastSale = 0.0;
    try {
      lastSale = double.parse(fields[2]);
    } catch (_) {}
    symbol = fields[0];
    name = fields[1];
    marketCap = fields[4];
    percentChange = (_rng.nextDouble() * 20) - 10;
  }
}

class StockData extends ChangeNotifier {
  StockData();

  List<Stock> get stocks => _stocks;

  final List<Stock> _stocks = <Stock>[];
  final HttpClient _httpClient = new HttpClient();
  int _nextChunk = 0;

  void add(List<Stock> data) {
    _stocks.addAll(data);
    notifyListeners();
  }

  static const int _kChunkCount = 5;

  String _urlToFetch(int chunk) {
    return 'https://pedia.github.io/examples/stocks/p$chunk.json';
  }

  Future<List<Stock>> fetchNextChunk() async {
    Completer completer = new Completer();
    if (_nextChunk <= _kChunkCount) {
      Uri url = Uri.parse(_urlToFetch(_nextChunk++));

      HttpClientRequest request = await _httpClient.getUrl(url);
      HttpClientResponse response = await request.close();

      final String body = await response.transform(utf8.decoder).join();

      List<Map> jsonList = json.decode(body) as List;
      List<Stock> result = jsonList.map((Object element) {
        return new Stock.fromFields(element as List);
      }).toList();

      add(result);

      completer.complete(result);
    } else {
      completer.complete(null);
    }

    return completer.future;
  }
}
