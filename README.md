# flutter_loadmore

A widget that supports idiom of "Pull Down to Refresh & Pull Up to Load More" for ListView .
Material never have this.

## Getting Started

add to pubspec.yaml
```txt
flutter_loadmore: ^2.0.1
```


```dart
import 'package:flutter_loadmore/flutter_loadmore.dart';

  Future<List<Demo>> _handleLoadMore() {
    // fetch data async
    return widget.provider.fetchNextChunk().then((_) {
      setState(() {});
    });
  }

  Widget build(BuildContext context) {
    return LoadMore(
      onLoadMore: _handleLoadMore,
      child: ListView.builder(
        itemCount: widget.provider.data.length,
        itemBuilder: (BuildContext context, int index) {
          final item = widget.provider.data[index];
          return ListTile(title: Text(item.name));
        },
      ),
    );
  }
```
Full example (fetch stock via HTTPS) in example folder.

