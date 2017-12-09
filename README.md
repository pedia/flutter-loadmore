# pdrpulm (Pull Down to Refresh & Pull Up to Load More)

A widget that supports "Pull Down to Refresh & Pull Up to Load More" idiom.
Google Material never have "Pull Up to Load More" so implement as a package.

## Getting Started

```
    return new RefreshAndLoadMoreIndicator(
        onRefresh: _handleRefresh,
        onLoadMore: _handleLoadMore,
        child: new ListView.builder(
```

## Known Bug

The indicator position may be wrong. 

