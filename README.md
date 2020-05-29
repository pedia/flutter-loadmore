# flutter-loadmore

A widget that supports idiom of "Pull Down to Refresh & Pull Up to Load More" for ListView .
Material never have this.

## Getting Started

```
  Widget createView(BuildContext context) {
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

