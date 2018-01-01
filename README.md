# pdrpulm (Pull Down to Refresh & Pull Up to Load More)

A widget that supports "Pull Down to Refresh & Pull Up to Load More" idiom.
Google Material never have "Pull Up to Load More" so implement as a package.

## Getting Started

```
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
```

## Roadmap

add custom indicator when refresh or loading more

