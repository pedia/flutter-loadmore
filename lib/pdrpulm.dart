// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The over-scroll distance that moves the indicator to its maximum
// displacement, as a percentage of the scrollable's container extent.
const double _kDragContainerExtentPercentage = 0.25;

// How much the scroll's drag gesture can overshoot the RefreshAndLoadMoreIndicator's
// displacement; max displacement = _kDragSizeFactorLimit * displacement.
const double _kDragSizeFactorLimit = 1.5;

// When the scroll ends, the duration of the refresh indicator's animation
// to the RefreshAndLoadMoreIndicator's displacment.
const Duration _kIndicatorSnapDuration = const Duration(milliseconds: 150);

// The duration of the ScaleTransition that starts when the refresh action
// has completed.
const Duration _kIndicatorScaleDuration = const Duration(milliseconds: 200);

/// The signature for a function that's called when the user has dragged a
/// [RefreshAndLoadMoreIndicator] far enough to demonstrate that they want the app to
/// refresh. The returned [Future] must complete when the refresh operation is
/// finished.
///
/// Used by [RefreshAndLoadMoreIndicator.onRefresh].
typedef Future<Null> RefreshCallback();
typedef Future<Null> LoadMoreCallback();

// The state machine moves through these modes only when the scrollable
// identified by scrollableKey has been scrolled to its min or max limit.
enum _RefreshAndLoadMoreIndicatorMode {
  drag,     // Pointer is down.
  armed,    // Dragged far enough that an up event will run the onRefresh callback.
  snap,     // Animating to the indicator's final "displacement".
  refresh,  // Running the refresh callback.
  done,     // Animating the indicator's fade-out after refreshing.
  canceled, // Animating the indicator's fade-out after not arming.
}

/// A widget that supports the Material "swipe to refresh" idiom.
///
/// When the child's [Scrollable] descendant overscrolls, an animated circular
/// progress indicator is faded into view. When the scroll ends, if the
/// indicator has been dragged far enough for it to become completely opaque,
/// the [onRefresh] callback is called. The callback is expected to update the
/// scrollable's contents and then complete the [Future] it returns. The refresh
/// indicator disappears after the callback's [Future] has completed.
///
/// If the [Scrollable] might not have enough content to overscroll, consider
/// settings its `physics` property to [AlwaysScrollableScrollPhysics]:
///
/// ```dart
/// new ListView(
///   physics: const AlwaysScrollableScrollPhysics(),
///   children: ...
//  )
/// ```
///
/// Using [AlwaysScrollableScrollPhysics] will ensure that the scroll view is
/// always scrollable and, therefore, can trigger the [RefreshAndLoadMoreIndicator].
///
/// A [RefreshAndLoadMoreIndicator] can only be used with a vertical scroll view.
///
/// See also:
///
///  * <https://material.google.com/patterns/swipe-to-refresh.html>
///  * [RefreshAndLoadMoreIndicatorState], can be used to programmatically show the refresh indicator.
///  * [RefreshProgressIndicator].
class RefreshAndLoadMoreIndicator extends StatefulWidget {
  /// Creates a refresh indicator.
  ///
  /// The [onRefresh], [child], and [notificationPredicate] arguments must be
  /// non-null. The default
  /// [displacement] is 40.0 logical pixels.
  const RefreshAndLoadMoreIndicator({
    Key key,
    @required this.child,
    this.displacement: 40.0,
    this.onRefresh,
    this.onLoadMore,
    this.color,
    this.backgroundColor,
    this.notificationPredicate: defaultScrollNotificationPredicate,
  }) : assert(child != null),
       assert(onRefresh != null || onLoadMore != null),
       assert(notificationPredicate != null),
       super(key: key);

  /// The refresh indicator will be stacked on top of this child. The indicator
  /// will appear when child's Scrollable descendant is over-scrolled.
  final Widget child;

  /// The distance from the child's top or bottom edge to where the refresh
  /// indicator will settle. During the drag that exposes the refresh indicator,
  /// its actual displacement may significantly exceed this value.
  final double displacement;

  /// A function that's called when the user has dragged the refresh indicator
  /// far enough to demonstrate that they want the app to refresh. The returned
  /// [Future] must complete when the refresh operation is finished.
  final RefreshCallback onRefresh;
  final LoadMoreCallback onLoadMore;

  /// The progress indicator's foreground color. The current theme's
  /// [ThemeData.accentColor] by default.
  final Color color;

  /// The progress indicator's background color. The current theme's
  /// [ThemeData.canvasColor] by default.
  final Color backgroundColor;
  
  /// A check that specifies whether a [ScrollNotification] should be
  /// handled by this widget.
  ///
  /// By default, checks whether `notification.depth == 0`. Set it to something
  /// else for more complicated layouts.
  final ScrollNotificationPredicate notificationPredicate;

  @override
  RefreshAndLoadMoreIndicatorState createState() => new RefreshAndLoadMoreIndicatorState();
}

/// Contains the state for a [RefreshAndLoadMoreIndicator]. This class can be used to
/// programmatically show the refresh indicator, see the [show] method.
class RefreshAndLoadMoreIndicatorState extends State<RefreshAndLoadMoreIndicator> with TickerProviderStateMixin {
  AnimationController _positionController;
  AnimationController _scaleController;
  Animation<double> _positionFactor;
  Animation<double> _scaleFactor;
  Animation<double> _value;
  Animation<Color> _valueColor;

  _RefreshAndLoadMoreIndicatorMode _mode;
  Future<Null> _pendingRefreshFuture;
  bool _isIndicatorAtTop;
  double _dragOffset;

  @override
  void initState() {
    super.initState();

    _positionController = new AnimationController(vsync: this);
    _positionFactor = new Tween<double>(
      begin: 0.0,
      end: _kDragSizeFactorLimit,
    ).animate(_positionController);
    _value = new Tween<double>( // The "value" of the circular progress indicator during a drag.
      begin: 0.0,
      end: 0.75,
    ).animate(_positionController);

    _scaleController = new AnimationController(vsync: this);
    _scaleFactor = new Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_scaleController);
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _valueColor = new ColorTween(
      begin: (widget.color ?? theme.accentColor).withOpacity(0.0),
      end: (widget.color ?? theme.accentColor).withOpacity(1.0)
    ).animate(new CurvedAnimation(
      parent: _positionController,
      curve: const Interval(0.0, 1.0 / _kDragSizeFactorLimit)
    ));
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _positionController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  AxisDirection direction(ScrollNotification notification) {
    AxisDirection res;
    if (notification.metrics.pixels < 0)
      res = AxisDirection.down;
    else if (notification.metrics.pixels > 0)
      res = AxisDirection.up;
    else
      res = notification.metrics.axisDirection;

    // if (notification.metrics.axisDirection != res)
    // print("notification $res ${notification.metrics.pixels}"
    //   " ${notification.metrics.axisDirection}"
    //   );
    return res;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification))
      return false;
    if (notification is ScrollEndNotification) {
      print("is end");
    }
    if (notification is ScrollStartNotification) {
      print("is start before: ${notification.metrics.extentBefore} ${notification.metrics.pixels} after: ${notification.metrics.extentAfter}, _mode: $_mode");
    }
    if (notification is ScrollStartNotification && 
        notification.metrics.extentAfter == 0.0 &&
        _mode == null && _start(direction(notification))) {
          print("_handle to drag(up)");
          setState(() {
            print("setState to drag(up)");
            _mode = _RefreshAndLoadMoreIndicatorMode.drag;
          });
      return false;
    }
    if (notification is ScrollStartNotification && notification.metrics.extentBefore == 0.0 &&
        _mode == null && _start(direction(notification))) {
      print("before _handle to drag");
      setState(() {
        print("_handle to drag");
        _mode = _RefreshAndLoadMoreIndicatorMode.drag;
      });
      return false;
    }
    bool indicatorAtTopNow;
    switch (notification.metrics.axisDirection) {
      case AxisDirection.down:
        indicatorAtTopNow = true;
        break;
      case AxisDirection.up:
        indicatorAtTopNow = false;
        break;
      case AxisDirection.left:
      case AxisDirection.right:
        indicatorAtTopNow = null;
        break;
    }
    indicatorAtTopNow = direction(notification) == AxisDirection.down;
    print("$indicatorAtTopNow != $_isIndicatorAtTop $_mode");
    if (indicatorAtTopNow != _isIndicatorAtTop) {
      if (_mode == _RefreshAndLoadMoreIndicatorMode.drag || _mode == _RefreshAndLoadMoreIndicatorMode.armed)
        print("_dismiss $_mode 1");
        _dismiss(_RefreshAndLoadMoreIndicatorMode.canceled);
    } else if (notification is ScrollUpdateNotification) {
      if (_mode == _RefreshAndLoadMoreIndicatorMode.drag || _mode == _RefreshAndLoadMoreIndicatorMode.armed) {
        // if (notification.metrics.extentBefore > 0.0) {
        //   print("_dismiss 2");
        //   _dismiss(_RefreshAndLoadMoreIndicatorMode.canceled);
        // } else {
          _dragOffset -= notification.scrollDelta;
          _checkDragOffset(notification.metrics.viewportDimension);
        // }
      }
    } else if (notification is OverscrollNotification) {
      if (_mode == _RefreshAndLoadMoreIndicatorMode.drag || _mode == _RefreshAndLoadMoreIndicatorMode.armed) {
        _dragOffset -= notification.overscroll / 2.0;
        _checkDragOffset(notification.metrics.viewportDimension);
      }
    } else if (notification is ScrollEndNotification) {
      print("end $_mode");
      switch (_mode) {
        case _RefreshAndLoadMoreIndicatorMode.armed:
          _show();
          break;
        case _RefreshAndLoadMoreIndicatorMode.drag:
          _dismiss(_RefreshAndLoadMoreIndicatorMode.canceled);
          break;
        default:
          // do nothing
          break;
      }
    }
    return false;
  }

  bool _handleGlowNotification(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading)
      return false;
    if (_mode == _RefreshAndLoadMoreIndicatorMode.drag) {
      notification.disallowGlow();
      return true;
    }
    return false;
  }

  bool _start(AxisDirection direction) {
    print("_start $direction");
    assert(_mode == null);
    assert(_isIndicatorAtTop == null);
    assert(_dragOffset == null);
    switch (direction) {
      case AxisDirection.down:
        _isIndicatorAtTop = true;
        break;
      case AxisDirection.up:
        _isIndicatorAtTop = false;
        break;
      case AxisDirection.left:
      case AxisDirection.right:
        _isIndicatorAtTop = null;
        // we do not support horizontal scroll views.
        return false;
    }
    _dragOffset = 0.0;
    _scaleController.value = 0.0;
    _positionController.value = 0.0;
    return true;
  }

  void _checkDragOffset(double containerExtent) {
    assert(_mode == _RefreshAndLoadMoreIndicatorMode.drag || _mode == _RefreshAndLoadMoreIndicatorMode.armed);
    double newValue = _dragOffset / (containerExtent * _kDragContainerExtentPercentage);
    if (_mode == _RefreshAndLoadMoreIndicatorMode.armed)
      newValue = math.max(newValue, 1.0 / _kDragSizeFactorLimit);
    _positionController.value = newValue.clamp(0.0, 1.0); // this triggers various rebuilds
    if (_mode == _RefreshAndLoadMoreIndicatorMode.drag && _valueColor.value.alpha == 0) {
      _mode = _RefreshAndLoadMoreIndicatorMode.armed;
    }
    if (_mode == _RefreshAndLoadMoreIndicatorMode.drag && _valueColor.value.alpha == 0xFF)
      _mode = _RefreshAndLoadMoreIndicatorMode.armed;
  }

  // Stop showing the refresh indicator.
  Future<Null> _dismiss(_RefreshAndLoadMoreIndicatorMode newMode) async {
    // This can only be called from _show() when refreshing and
    // _handleScrollNotification in response to a ScrollEndNotification or
    // direction change.
    assert(newMode == _RefreshAndLoadMoreIndicatorMode.canceled || newMode == _RefreshAndLoadMoreIndicatorMode.done);
    setState(() {
      print("dismiss $newMode");
      _mode = newMode;
    });
    switch (_mode) {
      case _RefreshAndLoadMoreIndicatorMode.done:
        await _scaleController.animateTo(1.0, duration: _kIndicatorScaleDuration);
        break;
      case _RefreshAndLoadMoreIndicatorMode.canceled:
        await _positionController.animateTo(0.0, duration: _kIndicatorScaleDuration);
        break;
      default:
        assert(false);
    }
    if (mounted && _mode == newMode) {
      _dragOffset = null;
      _isIndicatorAtTop = null;
      setState(() {
        print("dismiss");
        _mode = null;
      });
    }
  }

  void _show() {
    print("_show");
    assert(_mode != _RefreshAndLoadMoreIndicatorMode.refresh);
    assert(_mode != _RefreshAndLoadMoreIndicatorMode.snap);
    final Completer<Null> completer = new Completer<Null>();
    _pendingRefreshFuture = completer.future;
    _mode = _RefreshAndLoadMoreIndicatorMode.snap;
    _positionController
      .animateTo(1.0 / _kDragSizeFactorLimit, duration: _kIndicatorSnapDuration)
      .then<Null>((Null value) {
        if (mounted && _mode == _RefreshAndLoadMoreIndicatorMode.snap) {
          // assert(widget.onRefresh != null);
          print("before setState to refresh");
          setState(() {
            // Show the indeterminate progress indicator.
            print("to refresh");
            _mode = _RefreshAndLoadMoreIndicatorMode.refresh;
          });

          final Future<Null> refreshResult = widget.onRefresh();
          assert(() {
            if (refreshResult == null)
              FlutterError.reportError(new FlutterErrorDetails(
                exception: new FlutterError(
                  'The onRefresh callback returned null.\n'
                  'The RefreshAndLoadMoreIndicator onRefresh callback must return a Future.'
                ),
                context: 'when calling onRefresh',
                library: 'material library',
              ));
            return true;
          });
          if (refreshResult == null)
            return;
          refreshResult.whenComplete(() {
            if (mounted && _mode == _RefreshAndLoadMoreIndicatorMode.refresh) {
              completer.complete();
              _dismiss(_RefreshAndLoadMoreIndicatorMode.done);
            }
          });
        }
      });
  }

  /// Show the refresh indicator and run the refresh callback as if it had
  /// been started interactively. If this method is called while the refresh
  /// callback is running, it quietly does nothing.
  ///
  /// Creating the [RefreshAndLoadMoreIndicator] with a [GlobalKey<RefreshAndLoadMoreIndicatorState>]
  /// makes it possible to refer to the [RefreshAndLoadMoreIndicatorState].
  ///
  /// The future returned from this method completes when the
  /// [RefreshAndLoadMoreIndicator.onRefresh] callback's future completes.
  ///
  /// If you await the future returned by this function from a [State], you
  /// should check that the state is still [mounted] before calling [setState].
  ///
  /// When initiated in this manner, the refresh indicator is independent of any
  /// actual scroll view. It defaults to showing the indicator at the top. To
  /// show it at the bottom, set `atTop` to false.
  Future<Null> show({ bool atTop: true }) {
    if (_mode != _RefreshAndLoadMoreIndicatorMode.refresh &&
        _mode != _RefreshAndLoadMoreIndicatorMode.snap) {
      if (_mode == null)
        _start(atTop ? AxisDirection.down : AxisDirection.up);
      _show();
    }
    return _pendingRefreshFuture;
  }

  final GlobalKey _key = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    final Widget child = new NotificationListener<ScrollNotification>(
      key: _key,
      onNotification: _handleScrollNotification,
      child: new NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _handleGlowNotification,
        child: widget.child,
      ),
    );
    if (_mode == null) {
      assert(_dragOffset == null);
      assert(_isIndicatorAtTop == null);
      return child;
    }
    assert(_dragOffset != null);
    assert(_isIndicatorAtTop != null);
    print("build: $_isIndicatorAtTop");

    final bool showIndeterminateIndicator =
      _mode == _RefreshAndLoadMoreIndicatorMode.refresh || _mode == _RefreshAndLoadMoreIndicatorMode.done;

    return new Stack(
      children: <Widget>[
        child,
        new Positioned(
          top: _isIndicatorAtTop ? 0.0 : null,
          bottom: !_isIndicatorAtTop ? 0.0 : null,
          left: 0.0,
          right: 0.0,
          child: new SizeTransition(
            axisAlignment: _isIndicatorAtTop ? 1.0 : -1.0,
            sizeFactor: _positionFactor, // this is what brings it down
            child: new Container(
              padding: _isIndicatorAtTop
                ? new EdgeInsets.only(top: widget.displacement)
                : new EdgeInsets.only(bottom: widget.displacement),
              alignment: _isIndicatorAtTop
                ? Alignment.topCenter
                : Alignment.bottomCenter,
              child: new ScaleTransition(
                scale: _scaleFactor,
                child: new AnimatedBuilder(
                  animation: _positionController,
                  builder: (BuildContext context, Widget child) {
                    return new RefreshProgressIndicator(
                      value: showIndeterminateIndicator ? null : _value.value,
                      valueColor: _valueColor,
                      backgroundColor: widget.backgroundColor,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
