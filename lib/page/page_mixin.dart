import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:photo_browser/define.dart';
import 'package:photo_browser/pull_down_pop.dart';

mixin PageMixin<T extends StatefulWidget> on State<T> {
  BoxConstraints? mConstraints;
  Size? mImageSize;
  Offset mOffset = Offset.zero;
  double mScale = 1.0;
  Offset _normalizedOffset = Offset.zero;
  double _oldScale = 1.0;

  double mImageDefW = 0;
  double mImageDefH = 0;
  double _imageMaxFitW = 0;
  double _imageMaxFitH = 0;

  late AnimationController _scaleAnimationController;
  Animation<double>? _scaleAnimation;

  late AnimationController _positionAnimationController;
  Animation<Offset>? _positionAnimation;

  late AnimationController _pullDownScaleAnimationController;
  Animation<double>? _pullDownScaleAnimation;

  late AnimationController _pullDownPositionAnimationController;
  Animation<Offset>? _pullDownPositionAnimation;

  late AnimationController _pullDownBgColorScaleAnimationController;
  Animation<double>? _pullDownBgColorScaleAnimation;

  final Hit _hit = Hit();
  Map<Type, GestureRecognizerFactory>? _gestures;

  // 下拉pop用到的相关属性
  Offset _oldLocalFocalPoint = Offset.zero;
  Offset mPullDownContentOffset = Offset.zero;
  PullDownPopStatus _pullDownPopStatus = PullDownPopStatus.none;
  double mPullDownContentScale = 1.0;
  double mPullDownBgColorScale = 1.0;

  ///
  bool _allowZoom = true;
  bool _allowShrinkPhoto = true;
  bool _allowPullDownToPop = false;
  PullDownPopChanged? _pullDownPopChanged;
  late PullDownPopConfig _pullDownPopConfig;
  OnScaleChanged? _onScaleChanged;

  void mInitSet({
    bool allowZoom = true,
    bool allowShrinkPhoto = true,
    bool allowPullDownToPop = false,
    PullDownPopChanged? pullDownPopChanged,
    PullDownPopConfig pullDownPopConfig = const PullDownPopConfig(),
    OnScaleChanged? onScaleChanged,
  }) {
    _allowZoom = allowZoom;
    _allowShrinkPhoto = allowShrinkPhoto;
    _allowPullDownToPop = allowPullDownToPop;
    _pullDownPopChanged = pullDownPopChanged;
    _pullDownPopConfig = pullDownPopConfig;
    _onScaleChanged = onScaleChanged;
  }

  void mInitAnimationController(TickerProvider vsync) {
    _scaleAnimationController = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: vsync)
      ..addListener(_handleScaleAnimation);
    _positionAnimationController = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: vsync)
      ..addListener(_handlePositionAnimate);
    _pullDownScaleAnimationController = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: vsync)
      ..addListener(_handlePullDownScaleAnimation);
    _pullDownPositionAnimationController = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: vsync)
      ..addListener(_handlePullDownPositionAnimate);
    _pullDownBgColorScaleAnimationController = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: vsync)
      ..addListener(_handlePullDownBgColorScaleAnimation);
  }

  void mDisposeAnimationController() {
    _scaleAnimationController.removeListener(_handleScaleAnimation);
    _scaleAnimationController.dispose();
    _positionAnimationController.removeListener(_handlePositionAnimate);
    _positionAnimationController.dispose();
    _pullDownScaleAnimationController
        .removeListener(_handlePullDownScaleAnimation);
    _pullDownScaleAnimationController.dispose();
    _pullDownPositionAnimationController
        .removeListener(_handlePullDownPositionAnimate);
    _pullDownPositionAnimationController.dispose();
    _pullDownBgColorScaleAnimationController
        .removeListener(_handlePullDownBgColorScaleAnimation);
    _pullDownBgColorScaleAnimationController.dispose();
  }

  void _animateScale(double from, double to) {
    _scaleAnimation = Tween<double>(
      begin: from,
      end: to,
    ).animate(_scaleAnimationController);
    _scaleAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void _animatePosition(Offset from, Offset to) {
    _positionAnimation = Tween<Offset>(begin: from, end: to)
        .animate(_positionAnimationController);
    _positionAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void _animatePullDownScale(double from, double to) {
    _pullDownScaleAnimation = Tween<double>(
      begin: from,
      end: to,
    ).animate(_pullDownScaleAnimationController);
    _pullDownScaleAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void _animatePullDownPosition(Offset from, Offset to) {
    _pullDownPositionAnimation = Tween<Offset>(begin: from, end: to)
        .animate(_pullDownPositionAnimationController);
    _pullDownPositionAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void _animatePullDownBgColorScale(double from, double to) {
    _pullDownBgColorScaleAnimation = Tween<double>(
      begin: from,
      end: to,
    ).animate(_pullDownBgColorScaleAnimationController);
    _pullDownBgColorScaleAnimationController
      ..value = 0.0
      ..fling(velocity: 0.4);
  }

  void _handleScaleAnimation() {
    mScale = _scaleAnimation!.value;
    _setHit();
    setState(() {});
  }

  void _handlePositionAnimate() {
    mOffset = _positionAnimation!.value;
    setState(() {});
  }

  void _handlePullDownScaleAnimation() {
    mPullDownContentScale = _pullDownScaleAnimation!.value;
    setState(() {});
  }

  void _handlePullDownPositionAnimate() {
    mPullDownContentOffset = _pullDownPositionAnimation!.value;
    setState(() {});
  }

  void _handlePullDownBgColorScaleAnimation() {
    mPullDownBgColorScale = _pullDownBgColorScaleAnimation!.value;
    if (_pullDownPopChanged != null) {
      _pullDownPopChanged!(_pullDownPopStatus, mPullDownBgColorScale);
    }
    setState(() {});
  }

  bool mSetImageSize({BoxConstraints? constraints}) {
    if (constraints != null) {
      if (constraints.maxWidth == mConstraints?.maxWidth &&
          constraints.maxHeight == mConstraints?.maxHeight &&
          mImageDefW > 0 &&
          mImageDefH > 0) {
        return true;
      }
      // 比如旋转时，按默认比例及位置显示
      if (mConstraints != null &&
          (constraints.maxWidth != mConstraints?.maxWidth ||
              constraints.maxHeight != mConstraints?.maxHeight)) {
        mScale = 1;
        mOffset = Offset.zero;
        Future.delayed(const Duration(milliseconds: 0), () {
          setState(() {});
        });
      }
      mConstraints = constraints;
    }

    if (mImageSize == null) return false;
    if (mConstraints == null) return false;
    if (mConstraints!.maxWidth == 0 || mConstraints!.maxHeight == 0) {
      return false;
    }
    if (mImageSize!.width == 0 || mImageSize!.height == 0) return false;

    if (mImageSize!.width / mImageSize!.height >
        mConstraints!.maxWidth / mConstraints!.maxHeight) {
      mImageDefW = mConstraints!.maxWidth;
      mImageDefH = mImageDefW * mImageSize!.height / mImageSize!.width;
      _imageMaxFitH = mConstraints!.maxHeight;
      _imageMaxFitW = _imageMaxFitH * mImageSize!.width / mImageSize!.height;
    } else {
      mImageDefH = mConstraints!.maxHeight;
      mImageDefW = mImageDefH * mImageSize!.width / mImageSize!.height;
      _imageMaxFitW = mConstraints!.maxWidth;
      _imageMaxFitH = _imageMaxFitW * mImageSize!.height / mImageSize!.width;
    }
    return true;
  }

  void _onDoubleTap() {
    if (_allowZoom == false) return;
    if (mSetImageSize() == false) return;

    _scaleAnimationController.stop();
    _positionAnimationController.stop();

    double oldScale = mScale;
    Offset oldOffset = mOffset;
    double newScale = mScale;
    Offset newOffset = mOffset;

    if (mScale != 1) {
      newScale = 1;
      newOffset = Offset.zero;
    } else {
      if (mImageSize!.width / mImageSize!.height >
          mConstraints!.maxWidth / mConstraints!.maxHeight) {
        newScale = _imageMaxFitW / mConstraints!.maxWidth;
        newOffset = Offset((mConstraints!.maxWidth - _imageMaxFitW) * 0.5,
            (mImageDefH - _imageMaxFitH) * 0.5 * newScale);
      } else {
        newScale = _imageMaxFitH / mConstraints!.maxHeight;
        newOffset = Offset((mImageDefW - _imageMaxFitW) * 0.5 * newScale,
            (mConstraints!.maxHeight - _imageMaxFitH) * 0.5);
      }
    }
    if (_onScaleChanged != null) {
      _onScaleChanged!(newScale);
    }
    _animateScale(oldScale, newScale);
    _animatePosition(oldOffset, newOffset);
    _positionAnimationController.forward();
    _scaleAnimationController.forward();
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_allowZoom == false && details.pointerCount > 1) return;
    _oldScale = mScale;
    _normalizedOffset = (details.focalPoint - mOffset) / mScale;
    _oldLocalFocalPoint = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_allowZoom == false && details.pointerCount > 1) return;
    if (!_allowShrinkPhoto) {
      mScale = (_oldScale * details.scale).clamp(1.0, double.infinity);
      mOffset = _clampOffset(details.focalPoint - _normalizedOffset * mScale);
    } else {
      mScale = (_oldScale * details.scale).clamp(0.1, double.infinity);
      if (mScale > 1) {
        mOffset = _clampOffset(details.focalPoint - _normalizedOffset * mScale);
      } else {
        mOffset = Offset(
            (mConstraints!.maxWidth - mConstraints!.maxWidth * mScale) * 0.5,
            (mConstraints!.maxHeight - mConstraints!.maxHeight * mScale) * 0.5);
        _normalizedOffset = (details.focalPoint - mOffset) / mScale;
      }
    }
    if (_onScaleChanged != null && mScale != _oldScale) {
      _onScaleChanged!(mScale);
    }
    _setHit();
    _updatePullDownPop(details);
    setState(() {});
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_allowZoom == false && details.pointerCount > 1) return;
    _endPullDownPop(details);
    setState(() {});
  }

  Offset _clampOffset(Offset offset) {
    final Size size = context.size ?? Size.zero; //容器的大小
    final Offset minOffset = Offset(size.width, size.height) * (1.0 - mScale);
    return Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  void _setHit() {
    _hit.hitType = HitType.all;
    if (mScale > 1) {
      _hit.hitType = HitType.none;
      double rightDistance = (mOffset.dx -
              mConstraints!.maxWidth +
              mConstraints!.maxWidth * mScale)
          .abs();
      if (mOffset.dx.abs() < 0.01) {
        _hit.hitType = HitType.left;
      } else if (rightDistance < 0.01) {
        _hit.hitType = HitType.right;
      }
    }
  }

  void _updatePullDownPop(ScaleUpdateDetails details) {
    if (_allowPullDownToPop && details.pointerCount == 1 && mScale <= 1) {
      double dy = details.localFocalPoint.dy - _oldLocalFocalPoint.dy;
      double dx = details.localFocalPoint.dx - _oldLocalFocalPoint.dx;

      double rate = _pullDownPopConfig.changeRate;
      double contentMinScale = _pullDownPopConfig.contentMinScale;
      double bgColorMinOpacity = _pullDownPopConfig.bgColorMinOpacity;

      if (_pullDownPopStatus == PullDownPopStatus.pulling ||
          (dy > 0 && dy.abs() > dx.abs())) {
        _pullDownPopStatus = PullDownPopStatus.pulling;
        mPullDownContentOffset = Offset(mPullDownContentOffset.dx + dx,
            max(mPullDownContentOffset.dy + dy, 0));
        mPullDownContentScale = 1.0;
        mPullDownBgColorScale = 1.0;
        if (mConstraints?.maxHeight != null) {
          mPullDownContentScale = max(
              (mConstraints!.maxHeight * rate - mPullDownContentOffset.dy) /
                  (mConstraints!.maxHeight * rate),
              contentMinScale);
          mPullDownBgColorScale = max(
              (mConstraints!.maxHeight * rate - mPullDownContentOffset.dy) /
                  (mConstraints!.maxHeight * rate),
              bgColorMinOpacity);
          if (_pullDownPopChanged != null) {
            _pullDownPopChanged!(_pullDownPopStatus, mPullDownBgColorScale);
          }
        }
      }
      _oldLocalFocalPoint = details.localFocalPoint;
    }
  }

  void _endPullDownPop(ScaleEndDetails details) {
    double height = (mConstraints?.maxHeight ?? 0) * mPullDownContentScale;
    double dy = ((mConstraints?.maxHeight ?? 0) - height) * 0.5;
    final triggerD =
        (mConstraints?.maxHeight ?? 0) * _pullDownPopConfig.triggerScale;
    if (mPullDownContentOffset.dy + dy > triggerD) {
      _pullDownPopStatus = PullDownPopStatus.canPop;
    } else {
      _pullDownPopStatus = PullDownPopStatus.none;
      _animatePullDownScale(mPullDownContentScale, 1.0);
      _animatePullDownPosition(mPullDownContentOffset, Offset.zero);
      _animatePullDownBgColorScale(mPullDownBgColorScale, 1.0);
    }
    if (_pullDownPopChanged != null) {
      _pullDownPopChanged!(_pullDownPopStatus, mPullDownBgColorScale);
    }
  }

  mRawGestureDetector({required Widget child}) {
    return RawGestureDetector(
      gestures: _getGestures(),
      child: child,
    );
  }

  Map<Type, GestureRecognizerFactory> _getGestures() {
    if (_gestures != null) return _gestures!;
    _gestures = <Type, GestureRecognizerFactory>{};
    _gestures![CustomScaleGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<CustomScaleGestureRecognizer>(
      () => CustomScaleGestureRecognizer(this, _hit),
      (CustomScaleGestureRecognizer instance) {
        instance
          ..onStart = _onScaleStart
          ..onUpdate = _onScaleUpdate
          ..onEnd = _onScaleEnd;
      },
    );

    _gestures![DoubleTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
      () => DoubleTapGestureRecognizer(debugOwner: this),
      (DoubleTapGestureRecognizer instance) {
        instance.onDoubleTap = _onDoubleTap;
      },
    );
    return _gestures!;
  }

  Widget mBuildTransform(Widget child) {
    double width = (mConstraints?.maxWidth ?? 0) * mPullDownContentScale;
    double height = (mConstraints?.maxHeight ?? 0) * mPullDownContentScale;
    double dx = ((mConstraints?.maxWidth ?? 0) - width) * 0.5 * mScale;
    double dy = ((mConstraints?.maxHeight ?? 0) - height) * 0.5 * mScale;
    double x = mOffset.dx + mPullDownContentOffset.dx + dx;
    double y = mOffset.dy + mPullDownContentOffset.dy + dy;
    double scale = mScale * mPullDownContentScale;
    return Transform(
      transform: Matrix4.identity()
        ..translate(x, y)
        ..scale(scale, scale, 1.0),
      child: child,
    );
  }
}
