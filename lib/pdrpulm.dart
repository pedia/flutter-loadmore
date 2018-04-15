import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const kRefreshOffset = 40.0;
const kLoadMoreOffset = 30.0;

enum _PullIndicatorMode { idle, dragReleaseRefresh, dragReleaseLoadMore, dragReleaseCancel, refreshing, loading }

/// The signature for a function that's called when the user has dragged a
/// [ScrollIndicator] far enough to demonstrate that they want the app to
/// refresh or load more. The returned [Future] must complete when the
/// refresh or load more operation is finished.
///
/// Used by [ScrollIndicator.onRefresh] and [ScrollIndicator.onLoadMore]
typedef Future PullCallback();

class ScrollIndicator extends StatefulWidget {
  ScrollIndicator(
      {@required this.child, this.onRefresh, this.onLoadMore, this.refreshOffset = kRefreshOffset, this.loadMoreOffset = kLoadMoreOffset});

  final Widget child;
  final PullCallback onRefresh;
  final PullCallback onLoadMore;
  final double refreshOffset;
  final double loadMoreOffset;

  _ScrollIndicatorState createState() => new _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<ScrollIndicator> {
  double _dragOffset;
  _PullIndicatorMode _mode;

  void changeMode(_PullIndicatorMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  void handleResult(Future result) {
    assert(() {
      if (result == null)
        FlutterError.reportError(new FlutterErrorDetails(
          exception: new FlutterError('The onRefresh/onLoadMore callback returned null.\n'
              'The ScrollIndicator onRefresh/onLoadMore callback must return a Future.'),
          context: 'when calling onRefresh/onLoadMore',
          library: 'pdrpulm library',
        ));
      return true;
    }());
    if (result == null) return;
    result.whenComplete(() {
      if (mounted && _mode == _PullIndicatorMode.refreshing) {
        changeMode(_PullIndicatorMode.idle);
      }
      if (mounted && _mode == _PullIndicatorMode.loading) {
        changeMode(_PullIndicatorMode.idle);
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _dragOffset = 0.0;
      _mode = _PullIndicatorMode.dragReleaseCancel;
    }

    if (notification is UserScrollNotification) {}

    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails == null) {
        switch (_mode) {
          case _PullIndicatorMode.dragReleaseLoadMore:
            changeMode(_PullIndicatorMode.loading);
            _handleLoadMore();
            break;
          case _PullIndicatorMode.dragReleaseRefresh:
            changeMode(_PullIndicatorMode.refreshing);
            _handleRefresh();
            break;
          case _PullIndicatorMode.dragReleaseCancel:
            changeMode(_PullIndicatorMode.idle);
            break;
          default:
        }
      }

      _dragOffset -= notification.scrollDelta;

      if (_mode == _PullIndicatorMode.dragReleaseCancel ||
          _mode == _PullIndicatorMode.dragReleaseRefresh ||
          _mode == _PullIndicatorMode.dragReleaseLoadMore) {
        if (notification.metrics.extentBefore == 0.0 && _dragOffset > widget.refreshOffset) {
          changeMode(_PullIndicatorMode.dragReleaseRefresh);
        } else if (notification.metrics.extentBefore == 0.0) {
          changeMode(_PullIndicatorMode.dragReleaseCancel);
        }
        if (notification.metrics.extentAfter == 0.0 && _dragOffset < -widget.loadMoreOffset) {
          changeMode(_PullIndicatorMode.dragReleaseLoadMore);
        } else if (notification.metrics.extentAfter == 0.0) {
          changeMode(_PullIndicatorMode.dragReleaseCancel);
        }
      }
    }

    if (notification is OverscrollNotification) {}

    if (notification is ScrollEndNotification) {
//      _dragOffset = null;
//      changeMode(null);
    }
    return false;
  }

  void _handleRefresh() {
    if (widget.onRefresh != null) {
      handleResult(widget.onRefresh());
    }
  }

  void _handleLoadMore() {
    if (widget.onLoadMore != null) {
      handleResult(widget.onLoadMore());
    }
  }

  Widget build(BuildContext context) {
    if (_mode == _PullIndicatorMode.refreshing && _dragOffset > 0.0 && widget.onRefresh != null) {
      // TODO: Show Refresh Indicator
      print("refreshing");
    }

    if (_mode == _PullIndicatorMode.loading && _dragOffset < 0.0 && widget.onLoadMore != null) {
      // TODO: Show LoadMore Indicator
      print("loading");
    }

    if (_mode == _PullIndicatorMode.idle) {
      // TODO: hide the refresh and load more indicator
      print("idle");
    }

    return new NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.child,
    );
  }
}
