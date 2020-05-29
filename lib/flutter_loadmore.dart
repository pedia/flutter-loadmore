import 'dart:async';
import 'package:flutter/widgets.dart';

const int kDragOffset = 40;

enum _LoadMoreMode {
  drag,
  armed,
  // done,
  // canceled,
}

/// The signature for a function that's called when the user has dragged a
/// [LoadMore] far enough to demonstrate that they want the app to
/// refresh or load more. The returned [Future] must complete when the
/// refresh or load more operation is finished.
///
/// Used by [LoadMore.onRefresh] and [LoadMore.onLoadMore]
typedef PullCallback = Future Function();

class LoadMore extends StatefulWidget {
  LoadMore({@required this.child, this.onRefresh, this.onLoadMore});

  final Widget child;
  final PullCallback onRefresh;
  final PullCallback onLoadMore;

  _LoadMoreState createState() => _LoadMoreState();
}

class _LoadMoreState extends State<LoadMore> {
  double _dragOffset;
  _LoadMoreMode _mode;

  void changeMode(_LoadMoreMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  void handleResult(Future result) {
    assert(() {
      if (result == null)
        FlutterError.reportError(FlutterErrorDetails(
          exception: FlutterError(
              'The onRefresh/onLoadMore callback returned null.\n'
              'The LoadMore onRefresh/onLoadMore callback must return a Future.'),
          library: 'flutter_loadmore library',
        ));
      return true;
    }());

    if (result == null) return;

    result.whenComplete(() {
      if (mounted && _mode == _LoadMoreMode.armed) {
        changeMode(null);
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _dragOffset = 0.0;
      _mode = _LoadMoreMode.drag;
    }
    if (notification is ScrollUpdateNotification) {
      _dragOffset -= notification.scrollDelta;

      if (_mode == _LoadMoreMode.drag) {
        if (notification.metrics.extentBefore == 0.0 &&
            _dragOffset > kDragOffset) {
          changeMode(_LoadMoreMode.armed);
          if (widget.onRefresh != null) {
            handleResult(widget.onRefresh());
          }
        }
        if (notification.metrics.extentAfter == 0.0 &&
            _dragOffset < -kDragOffset) {
          changeMode(_LoadMoreMode.armed);
          if (widget.onLoadMore != null) {
            handleResult(widget.onLoadMore());
          }
        }
      }
    }
    if (notification is ScrollEndNotification) {
      _dragOffset = null;
      changeMode(null);
    }
    return false;
  }

  Widget build(BuildContext context) {
    if (_mode == _LoadMoreMode.armed && _dragOffset > 0.0) {
      // TODO: Show Refresh Indicator
    }

    if (_mode == _LoadMoreMode.armed && _dragOffset < 0.0) {
      // TODO: Show LoadMore Indicator
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.child,
    );
  }
}
