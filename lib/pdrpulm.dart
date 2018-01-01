import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

final kDragOffset = 40.0;

enum _PullIndicatorMode { drag, armed, done, canceled }

/// The signature for a function that's called when the user has dragged a
/// [ScrollIndicator] far enough to demonstrate that they want the app to
/// refresh or load more. The returned [Future] must complete when the 
/// refresh or load more operation is finished.
/// 
/// Used by [ScrollIndicator.onRefresh] and [ScrollIndicator.onLoadMore]
typedef Future<Null> PullCallback();

class ScrollIndicator extends StatefulWidget {
  ScrollIndicator({@required this.child, this.onRefresh, this.onLoadMore});

  final Widget child;
  final PullCallback onRefresh;
  final PullCallback onLoadMore;

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

  void handleResult(Future<Null> result) {
    assert(() {
      if (result == null)
        FlutterError.reportError(new FlutterErrorDetails(
          exception: new FlutterError(
              'The onRefresh/onLoadMore callback returned null.\n'
              'The ScrollIndicator onRefresh/onLoadMore callback must return a Future.'),
          context: 'when calling onRefresh/onLoadMore',
          library: 'pdrpulm library',
        ));
      return true;
    });
    if (result == null) return;
    result.whenComplete(() {
      if (mounted && _mode == _PullIndicatorMode.armed) {
        changeMode(null);
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _dragOffset = 0.0;
      _mode = _PullIndicatorMode.drag;
    }
    if (notification is ScrollUpdateNotification) {
      _dragOffset -= notification.scrollDelta;

      if (_mode == _PullIndicatorMode.drag) {
        if (notification.metrics.extentBefore == 0.0 &&
            _dragOffset > kDragOffset) {
          changeMode(_PullIndicatorMode.armed);
          if (widget.onRefresh != null) {
            handleResult(widget.onRefresh());
          }
        }
        if (notification.metrics.extentAfter == 0.0 &&
            _dragOffset < -kDragOffset) {
          changeMode(_PullIndicatorMode.armed);
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
    if (_mode == _PullIndicatorMode.armed && _dragOffset > 0.0) {
      // TODO: Show Refresh Indicator
    }

    if (_mode == _PullIndicatorMode.armed && _dragOffset < 0.0) {
      // TODO: Show LoadMore Indicator
    }
    return new NotificationListener(
        onNotification: _handleScrollNotification, child: widget.child);
  }
}
