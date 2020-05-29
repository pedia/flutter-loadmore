import 'dart:async';
import 'dart:convert';
import 'dart:io';

class Demo {
  Demo({
    this.id,
    this.ticker,
    this.name,
    this.lei,
    this.cik,
  });
  final String id;
  final String ticker;
  final String name;
  final String lei;
  final String cik;

  factory Demo.fromJson(Map map) {
    return Demo(
      id: map['id'],
      ticker: map['ticker'],
      name: map['name'],
      lei: map['lei'],
      cik: map['cik'],
    );
  }
}

class Provider {
  final List<Demo> data = <Demo>[];
  final HttpClient _httpClient = HttpClient();
  String _nextChunk = '';

  String _buildUrl() {
    var arr = [
      'https://api-v2.intrinio.com/companies?api_key=OjdjMWQxNGZlYTFlZWRiYzE0ZmFiNTJlOTIwZWYwMWI4&page_size=10',
      if (_nextChunk != null && _nextChunk.isNotEmpty) 'next_page=$_nextChunk'
    ];
    return arr.join('&');
  }

  Future<List<Demo>> fetchNextChunk() async {
    if (_nextChunk == null) return <Demo>[];
    
    final Uri url = Uri.parse(_buildUrl());
    print(url);

    HttpClientRequest request = await _httpClient.getUrl(url);
    HttpClientResponse response = await request.close();

    final String body = await response.transform(utf8.decoder).join();
    final Map jd = json.decode(body) as Map;

    _nextChunk = jd['next_page'];

    final List<Demo> result = (jd['companies'] as List).map((entry) {
      return Demo.fromJson(entry);
    }).toList();

    data.addAll(result);
    return result;
  }
}
