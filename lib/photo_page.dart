import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_browser/photo_browser.dart';

enum PullDownPopStatus {
  none,
  pulling,
  canPop,
}

typedef LoadingBuilder = Widget Function(
  BuildContext context,
  double progress,
);

typedef OnPhotoScaleChanged = void Function(double scale);

typedef ImageLoadSuccess = void Function(ImageInfo imageInfo);

typedef PullDownPopChanged = void Function(
    PullDownPopStatus status, double pullScale);

enum _ImageLoadStatus {
  loading,
  failed,
  completed,
}

class ImageProviderInfo {
  ImageProvider imageProvider;
  Size? imageSize;
  _ImageLoadStatus? status;
  ImageChunkEvent? imageChunkEvent;
  ImageInfo? imageInfo;

  ImageProviderInfo(this.imageProvider);
}

class PhotoPage extends StatefulWidget {
  PhotoPage({
    Key? key,
    required this.imageProvider,
    this.thumImageProvider,
    this.loadingBuilder,
    this.loadFailedChild,
    this.backcolor,
    this.heroTag,
    this.routeType = RouteType.fade,
    this.allowShrinkPhoto = true,
    this.willPop = false,
    this.gaplessPlayback,
    this.allowPullDownToPop = false,
    this.pullDownPopConfig = const PullDownPopConfig(),
    this.filterQuality,
    this.imageLoadSuccess,
    this.thumImageLoadSuccess,
    this.onPhotoScaleChanged,
    this.pullDownPopChanged,
  }) : super(key: key);

  final ImageProvider imageProvider;
  final ImageProvider? thumImageProvider;
  final LoadingBuilder? loadingBuilder;
  final Widget? loadFailedChild;
  final Color? backcolor;
  final String? heroTag;
  final RouteType routeType;
  final bool allowShrinkPhoto;
  final bool willPop;
  final bool allowPullDownToPop;
  final PullDownPopConfig pullDownPopConfig;
  final bool? gaplessPlayback;
  final FilterQuality? filterQuality;
  final ImageLoadSuccess? imageLoadSuccess;
  final ImageLoadSuccess? thumImageLoadSuccess;
  final OnPhotoScaleChanged? onPhotoScaleChanged;
  final PullDownPopChanged? pullDownPopChanged;

  @override
  State<StatefulWidget> createState() {
    return _PhotoPageState();
  }
}

class _PhotoPageState extends State<PhotoPage> with TickerProviderStateMixin {
  late ImageProviderInfo _imageProviderInfo;
  ImageProviderInfo? _thumImageProvideInfo;

  Size? _imageSize;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset = Offset.zero;
  double _oldScale = 1.0;

  double _imageDefW = 0;
  double _imageDefH = 0;
  double _imageMaxFitW = 0;
  double _imageMaxFitH = 0;

  BoxConstraints? _constraints;

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

  _Hit _hit = _Hit();

  // 下拉pop用到的相关属性
  Offset _oldLocalFocalPoint = Offset.zero;
  Offset _pullDownContentOffset = Offset.zero;
  PullDownPopStatus _pullDownPopStatus = PullDownPopStatus.none;
  double _pullDownContentScale = 1.0;
  double _pullDownBgColorScale = 1.0;

  @override
  void initState() {
    super.initState();

    _scaleAnimationController =
        AnimationController(duration: Duration(milliseconds: 120), vsync: this)
          ..addListener(_handleScaleAnimation);
    _positionAnimationController =
        AnimationController(duration: Duration(milliseconds: 120), vsync: this)
          ..addListener(_handlePositionAnimate);
    _pullDownScaleAnimationController =
        AnimationController(duration: Duration(milliseconds: 120), vsync: this)
          ..addListener(_handlePullDownScaleAnimation);
    _pullDownPositionAnimationController =
        AnimationController(duration: Duration(milliseconds: 120), vsync: this)
          ..addListener(_handlePullDownPositionAnimate);
    _pullDownBgColorScaleAnimationController =
        AnimationController(duration: Duration(milliseconds: 120), vsync: this)
          ..addListener(_handlePullDownBgColorScaleAnimation);

    _getImageInfo();
    _getThumImageInfo();
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  void _getImageInfo() async {
    _imageProviderInfo = ImageProviderInfo(widget.imageProvider);
    var imageInfo = await _getImage(_imageProviderInfo);
    if (widget.imageLoadSuccess != null) {
      widget.imageLoadSuccess!(imageInfo);
    }
  }

  void _getThumImageInfo() async {
    if (widget.thumImageProvider == null) return;
    _thumImageProvideInfo = ImageProviderInfo(widget.thumImageProvider!);
    var imageInfo = await _getImage(_thumImageProvideInfo!);
    if (widget.thumImageLoadSuccess != null) {
      widget.thumImageLoadSuccess!(imageInfo);
    }
  }

  Future<ImageInfo> _getImage(ImageProviderInfo providerInfo) async {
    if (providerInfo.imageInfo != null) return providerInfo.imageInfo!;
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    providerInfo.status = _ImageLoadStatus.loading;
    final ImageStream stream = providerInfo.imageProvider.resolve(
      const ImageConfiguration(),
    );
    final listener = ImageStreamListener((
      ImageInfo info,
      bool synchronousCall,
    ) {
      if (!completer.isCompleted) {
        completer.complete(info);
        if (mounted) {
          final setupCallback = () {
            providerInfo.imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
            providerInfo.status = _ImageLoadStatus.completed;
            providerInfo.imageChunkEvent = null;
            providerInfo.imageInfo = info;
            _imageSize = providerInfo.imageSize;
            _setImageSize();
          };
          synchronousCall ? setupCallback() : setState(setupCallback);
        }
      }
    }, onChunk: (event) {
      if (mounted) {
        setState(() => providerInfo.imageChunkEvent = event);
      }
    }, onError: (exception, stackTrace) {
      if (!mounted) {
        return;
      }
      // 释放缓存，避免下次加载直接失败
      providerInfo.imageProvider.evict();
      setState(() {
        providerInfo.status = _ImageLoadStatus.failed;
      });
      FlutterError.reportError(
        FlutterErrorDetails(exception: exception, stack: stackTrace),
      );
    });
    stream.addListener(listener);
    completer.future.then((_) {
      stream.removeListener(listener);
      providerInfo.status = _ImageLoadStatus.completed;
    });
    return completer.future;
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
    _scale = _scaleAnimation!.value;
    _setHit();
    setState(() {});
  }

  void _handlePositionAnimate() {
    _offset = _positionAnimation!.value;
    setState(() {});
  }

  void _handlePullDownScaleAnimation() {
    _pullDownContentScale = _pullDownScaleAnimation!.value;
    setState(() {});
  }

  void _handlePullDownPositionAnimate() {
    _pullDownContentOffset = _pullDownPositionAnimation!.value;
    setState(() {});
  }

  void _handlePullDownBgColorScaleAnimation() {
    _pullDownBgColorScale = _pullDownBgColorScaleAnimation!.value;
    if (widget.pullDownPopChanged != null) {
      widget.pullDownPopChanged!(_pullDownPopStatus, _pullDownBgColorScale);
    }
    setState(() {});
  }

  bool _setImageSize() {
    if (_imageDefW > 0 && _imageDefH > 0) return true;

    if (_imageSize == null) return false;
    if (_constraints == null) return false;
    if (_constraints!.maxWidth == 0 || _constraints!.maxHeight == 0)
      return false;
    if (_imageSize!.width == 0 || _imageSize!.height == 0) return false;

    if (_imageSize!.width / _imageSize!.height >
        _constraints!.maxWidth / _constraints!.maxHeight) {
      _imageDefW = _constraints!.maxWidth;
      _imageDefH = _imageDefW * _imageSize!.height / _imageSize!.width;
      _imageMaxFitH = _constraints!.maxHeight;
      _imageMaxFitW = _imageMaxFitH * _imageSize!.width / _imageSize!.height;
    } else {
      _imageDefH = _constraints!.maxHeight;
      _imageDefW = _imageDefH * _imageSize!.width / _imageSize!.height;
      _imageMaxFitW = _constraints!.maxWidth;
      _imageMaxFitH = _imageMaxFitW * _imageSize!.height / _imageSize!.width;
    }
    return true;
  }

  void _onDoubleTap() {
    if (_setImageSize() == false) return;

    _scaleAnimationController.stop();
    _positionAnimationController.stop();

    double oldScale = _scale;
    Offset oldOffset = _offset;
    double newScale = _scale;
    Offset newOffset = _offset;

    if (_scale != 1) {
      newScale = 1;
      newOffset = Offset.zero;
    } else {
      if (_imageSize!.width / _imageSize!.height >
          _constraints!.maxWidth / _constraints!.maxHeight) {
        newScale = _imageMaxFitW / _constraints!.maxWidth;
        newOffset = Offset((_constraints!.maxWidth - _imageMaxFitW) * 0.5,
            (_imageDefH - _imageMaxFitH) * 0.5 * newScale);
      } else {
        newScale = _imageMaxFitH / _constraints!.maxHeight;
        newOffset = Offset((_imageDefW - _imageMaxFitW) * 0.5 * newScale,
            (_constraints!.maxHeight - _imageMaxFitH) * 0.5);
      }
    }
    if (widget.onPhotoScaleChanged != null) {
      widget.onPhotoScaleChanged!(newScale);
    }
    _animateScale(oldScale, newScale);
    _animatePosition(oldOffset, newOffset);
    _positionAnimationController.forward();
    _scaleAnimationController.forward();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _oldScale = _scale;
    _normalizedOffset = (details.focalPoint - _offset) / _scale;
    _oldLocalFocalPoint = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.allowShrinkPhoto) {
      _scale = (_oldScale * details.scale).clamp(1.0, double.infinity);
      _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
    } else {
      _scale = (_oldScale * details.scale).clamp(0.1, double.infinity);
      if (_scale > 1) {
        _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
      } else {
        _offset = Offset(
            (_constraints!.maxWidth - _constraints!.maxWidth * _scale) * 0.5,
            (_constraints!.maxHeight - _constraints!.maxHeight * _scale) * 0.5);
        _normalizedOffset = (details.focalPoint - _offset) / _scale;
      }
    }
    if (widget.onPhotoScaleChanged != null && _scale != _oldScale) {
      widget.onPhotoScaleChanged!(_scale);
    }
    _setHit();
    _updatePullDownPop(details);
    setState(() {});
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _endPullDownPop(details);
    setState(() {});
  }

  Offset _clampOffset(Offset offset) {
    final Size size = context.size ?? Size.zero; //容器的大小
    final Offset minOffset =
        new Offset(size.width, size.height) * (1.0 - _scale);
    return new Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  void _setHit() {
    _hit.hitType = _HitType.all;
    if (_scale > 1) {
      _hit.hitType = _HitType.none;
      double rightDistance =
          (_offset.dx - (_imageDefW - _constraints!.maxWidth * _scale)).abs();
      if (_offset.dx.abs() < 0.01) {
        _hit.hitType = _HitType.left;
      } else if (rightDistance < 0.01) {
        _hit.hitType = _HitType.right;
      }
    }
  }

  void _updatePullDownPop(ScaleUpdateDetails details) {
    if (widget.allowPullDownToPop && details.pointerCount == 1 && _scale <= 1) {
      double dy = details.localFocalPoint.dy - _oldLocalFocalPoint.dy;
      double dx = details.localFocalPoint.dx - _oldLocalFocalPoint.dx;

      double rate = widget.pullDownPopConfig.changeRate;
      double contentMinScale = widget.pullDownPopConfig.contentMinScale;
      double bgColorMinOpacity = widget.pullDownPopConfig.bgColorMinOpacity;

      if (_pullDownPopStatus == PullDownPopStatus.pulling ||
          (dy > 0 && dy.abs() > dx.abs())) {
        _pullDownPopStatus = PullDownPopStatus.pulling;
        _pullDownContentOffset = Offset(_pullDownContentOffset.dx + dx,
            max(_pullDownContentOffset.dy + dy, 0));
        _pullDownContentScale = 1.0;
        _pullDownBgColorScale = 1.0;
        if (_constraints?.maxHeight != null) {
          _pullDownContentScale = max(
              (_constraints!.maxHeight * rate - _pullDownContentOffset.dy) /
                  (_constraints!.maxHeight * rate),
              contentMinScale);
          _pullDownBgColorScale = max(
              (_constraints!.maxHeight * rate - _pullDownContentOffset.dy) /
                  (_constraints!.maxHeight * rate),
              bgColorMinOpacity);
          if (widget.pullDownPopChanged != null) {
            widget.pullDownPopChanged!(
                _pullDownPopStatus, _pullDownBgColorScale);
          }
        }
      }
      _oldLocalFocalPoint = details.localFocalPoint;
    }
  }

  void _endPullDownPop(ScaleEndDetails details) {
    double height = (_constraints?.maxHeight ?? 0) * _pullDownContentScale;
    double dy = ((_constraints?.maxHeight ?? 0) - height) * 0.5;
    final triggerD =
        (_constraints?.maxHeight ?? 0) * widget.pullDownPopConfig.triggerScale;
    if (_pullDownContentOffset.dy + dy > triggerD) {
      _pullDownPopStatus = PullDownPopStatus.canPop;
    } else {
      _pullDownPopStatus = PullDownPopStatus.none;
      _animatePullDownScale(_pullDownContentScale, 1.0);
      _animatePullDownPosition(_pullDownContentOffset, Offset.zero);
      _animatePullDownBgColorScale(_pullDownBgColorScale, 1.0);
    }
    if (widget.pullDownPopChanged != null) {
      widget.pullDownPopChanged!(_pullDownPopStatus, _pullDownBgColorScale);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageProviderInfo.status == _ImageLoadStatus.failed &&
        (_thumImageProvideInfo == null ||
            _thumImageProvideInfo?.status == _ImageLoadStatus.failed)) {
      return _buildLoadFailed();
    }

    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    gestures[_ScaleGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_ScaleGestureRecognizer>(
      () => _ScaleGestureRecognizer(this, _hit),
      (_ScaleGestureRecognizer instance) {
        instance
          ..onStart = _onScaleStart
          ..onUpdate = _onScaleUpdate
          ..onEnd = _onScaleEnd;
      },
    );

    gestures[DoubleTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
      () => DoubleTapGestureRecognizer(debugOwner: this),
      (DoubleTapGestureRecognizer instance) {
        instance..onDoubleTap = _onDoubleTap;
      },
    );

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        _constraints = constraints;
        _setImageSize();
        Widget content;
        if (_thumImageProvideInfo == null ||
            _imageProviderInfo.status == _ImageLoadStatus.completed) {
          content = _buildContent(context, constraints, _imageProviderInfo);
        } else {
          content = _buildContent(context, constraints, _thumImageProvideInfo!);
        }

        double width = (_constraints?.maxWidth ?? 0) * _pullDownContentScale;
        double height = (_constraints?.maxHeight ?? 0) * _pullDownContentScale;
        double dx = ((_constraints?.maxWidth ?? 0) - width) * 0.5 * _scale;
        double dy = ((_constraints?.maxHeight ?? 0) - height) * 0.5 * _scale;
        double x = _pullDownContentOffset.dx + dx;
        double y = _pullDownContentOffset.dy + dy;

        return RawGestureDetector(
          gestures: gestures,
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: (widget.backcolor ?? Colors.black)
                .withOpacity(_pullDownBgColorScale),
            child: ClipRect(
              child: widget.willPop
                  ? content
                  : Stack(
                      children: [
                        Positioned(
                          left: x,
                          top: y,
                          width: width,
                          height: height,
                          child: content,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints,
      ImageProviderInfo providerInfo) {
    if (providerInfo.status == _ImageLoadStatus.completed) {
      return _buildImage(constraints, providerInfo.imageProvider);
    } else {
      return _buildLoading(imageChunkEvent: providerInfo.imageChunkEvent);
    }
  }

  Widget _buildImage(BoxConstraints constraints, ImageProvider imageProvider) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: double.maxFinite,
        minHeight: double.infinity,
      ),
      child: widget.heroTag != null && widget.routeType != RouteType.scale
          ? _buildHeroImage(imageProvider)
          : _buildTransformImage(imageProvider),
    );
  }

  Widget _buildHeroImage(ImageProvider imageProvider) {
    if (widget.willPop) {
      if (_pullDownBgColorScale < 1) {
        double posW = (_constraints?.maxWidth ?? 0) * _pullDownContentScale;
        double posH = (_constraints?.maxHeight ?? 0) * _pullDownContentScale;
        double dx = ((_constraints?.maxWidth ?? 0) - posW) * 0.5;
        double dy = ((_constraints?.maxHeight ?? 0) - posH) * 0.5;
        double posX = _pullDownContentOffset.dx + dx;
        double posY = _pullDownContentOffset.dy + dy;
        double imageW = _imageDefW * _scale * _pullDownContentScale;
        double imageH = _imageDefH * _scale * _pullDownContentScale;
        return CustomSingleChildLayout(
          delegate: _SingleChildLayoutDelegate(
            Size(posW, posH),
            Offset(posX, posY),
          ),
          child: Container(
            width: posW,
            height: posH,
            alignment: Alignment.center,
            child: Hero(
              tag: widget.heroTag!,
              child: Image(
                image: imageProvider,
                gaplessPlayback: widget.gaplessPlayback ?? false,
                filterQuality: widget.filterQuality ?? FilterQuality.high,
                fit: BoxFit.contain,
                width: imageW,
                height: imageH,
              ),
            ),
          ),
        );
      }
      double x =
          (_constraints!.maxWidth - _imageDefW) * _scale * 0.5 + _offset.dx;
      double y =
          (_constraints!.maxHeight - _imageDefH) * _scale * 0.5 + _offset.dy;
      double width = _imageDefW * _scale * _pullDownContentScale;
      double height = _imageDefH * _scale * _pullDownContentScale;
      return CustomSingleChildLayout(
        delegate: _SingleChildLayoutDelegate(
          Size(width, height),
          Offset(x, y),
        ),
        child: Hero(
          tag: widget.heroTag!,
          child: Image(
            image: imageProvider,
            gaplessPlayback: widget.gaplessPlayback ?? false,
            filterQuality: widget.filterQuality ?? FilterQuality.high,
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    return Hero(
      tag: widget.heroTag!,
      child: _buildTransformImage(imageProvider),
    );
  }

  Widget _buildTransformImage(ImageProvider imageProvider) {
    return Transform(
      transform: new Matrix4.identity()
        ..translate(_offset.dx, _offset.dy)
        ..scale(_scale, _scale, 1.0),
      child: Image(
        image: imageProvider,
        gaplessPlayback: widget.gaplessPlayback ?? false,
        filterQuality: widget.filterQuality ?? FilterQuality.high,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLoading({ImageChunkEvent? imageChunkEvent}) {
    double progress = 0.0;
    if (imageChunkEvent?.cumulativeBytesLoaded != null &&
        imageChunkEvent?.expectedTotalBytes != null) {
      progress = imageChunkEvent!.cumulativeBytesLoaded /
          imageChunkEvent.expectedTotalBytes!;
    }
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, progress);
    }
    return Center(
      child: Container(
        width: 40.0,
        height: 40.0,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor:
              new AlwaysStoppedAnimation<Color>(Colors.white.withAlpha(230)),
          value: progress,
        ),
      ),
    );
  }

  Widget _buildLoadFailed() {
    return widget.loadFailedChild ?? Container();
  }
}

class _SingleChildLayoutDelegate extends SingleChildLayoutDelegate {
  const _SingleChildLayoutDelegate(
    this.subjectSize,
    this.offset,
  );

  final Size subjectSize;
  final Offset offset;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return offset;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.tight(subjectSize);
  }

  @override
  bool shouldRelayout(_SingleChildLayoutDelegate oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SingleChildLayoutDelegate &&
          runtimeType == other.runtimeType &&
          subjectSize == other.subjectSize &&
          offset == other.offset;

  @override
  int get hashCode => subjectSize.hashCode ^ offset.hashCode;
}

class _ScaleGestureRecognizer extends ScaleGestureRecognizer {
  _ScaleGestureRecognizer(
    Object debugOwner,
    this.hit,
  ) : super(debugOwner: debugOwner);

  final _Hit hit;

  Map<int, Offset> _pointerLocations = <int, Offset>{};
  Offset? _initialFocalPoint;
  Offset? _currentFocalPoint;

  bool ready = true;

  @override
  void addAllowedPointer(event) {
    if (ready) {
      ready = false;
      _pointerLocations = <int, Offset>{};
    }
    super.addAllowedPointer(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    ready = true;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    _computeEvent(event);
    _updateDistances();
    _decideIfWeAcceptEvent(event);
    super.handleEvent(event);
  }

  void _computeEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (!event.synthesized) {
        _pointerLocations[event.pointer] = event.position;
      }
    } else if (event is PointerDownEvent) {
      _pointerLocations[event.pointer] = event.position;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerLocations.remove(event.pointer);
    }

    _initialFocalPoint = _currentFocalPoint;
  }

  void _updateDistances() {
    final int count = _pointerLocations.keys.length;
    Offset focalPoint = Offset.zero;
    for (int pointer in _pointerLocations.keys)
      focalPoint += _pointerLocations[pointer]!;
    _currentFocalPoint =
        count > 0 ? focalPoint / count.toDouble() : Offset.zero;
  }

  void _decideIfWeAcceptEvent(PointerEvent event) {
    if (!(event is PointerMoveEvent)) {
      return;
    }
    final move = _initialFocalPoint! - _currentFocalPoint!;
    if (hit.hitType == _HitType.none ||
        (hit.hitType == _HitType.left && move.dx > 0) ||
        (hit.hitType == _HitType.right && move.dx < 0)) {
      resolve(GestureDisposition.accepted);
    }
  }
}

enum _HitType {
  all,
  left,
  right,
  none,
}

class _Hit {
  _HitType hitType = _HitType.all;
}

class PullDownPopConfig {
  /// 触发pop的下拉距离占全屏的比例
  /// 取值范围：(0.0, 1.0)
  final double triggerScale;

  /// 背景色最小透明度
  /// 取值范围：[0.0, 1.0]
  final double bgColorMinOpacity;

  /// 下拉时内容缩小的最小比例
  /// 取值范围：(0.0~1.0]
  final double contentMinScale;

  /// 下拉时图片大小、背景色透明度变化的快慢
  /// 取值范围：(0.0~1.0]，值越小变化越快
  final double changeRate;
  const PullDownPopConfig(
      {double? triggerScale,
      double? bgColorMinOpacity,
      double? contentMinScale,
      double? changeRate})
      : this.triggerScale =
            (triggerScale != null && triggerScale < 1 && triggerScale > 0)
                ? triggerScale
                : 0.2,
        this.bgColorMinOpacity = (bgColorMinOpacity != null &&
                bgColorMinOpacity <= 1 &&
                bgColorMinOpacity >= 0)
            ? bgColorMinOpacity
            : 0.0,
        this.contentMinScale = (contentMinScale != null &&
                contentMinScale <= 1 &&
                contentMinScale > 0)
            ? contentMinScale
            : 0.4,
        this.changeRate =
            (changeRate != null && changeRate <= 1 && changeRate > 0)
                ? changeRate
                : 0.25;
}
