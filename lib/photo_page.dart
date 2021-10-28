import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_browser/define.dart';
import 'package:photo_browser/photo_browser.dart';
import 'package:photo_browser/pull_down_pop.dart';

typedef LoadingBuilder = Widget Function(
  BuildContext context,
  double progress,
);

typedef OnScaleChanged = void Function(double scale);

typedef ImageLoadSuccess = void Function(ImageInfo imageInfo);

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
    this.imageColor,
    this.imageColorBlendMode,
    this.filterQuality,
    this.imageLoadSuccess,
    this.thumImageLoadSuccess,
    this.onScaleChanged,
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
  final Color? imageColor;
  final BlendMode? imageColorBlendMode;
  final bool? gaplessPlayback;
  final FilterQuality? filterQuality;
  final ImageLoadSuccess? imageLoadSuccess;
  final ImageLoadSuccess? thumImageLoadSuccess;
  final OnScaleChanged? onScaleChanged;
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

  Hit _hit = Hit();

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
    if (widget.onScaleChanged != null) {
      widget.onScaleChanged!(newScale);
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
    if (widget.onScaleChanged != null && _scale != _oldScale) {
      widget.onScaleChanged!(_scale);
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
    _hit.hitType = HitType.all;
    if (_scale > 1) {
      _hit.hitType = HitType.none;
      double rightDistance =
          (_offset.dx - (_imageDefW - _constraints!.maxWidth * _scale)).abs();
      if (_offset.dx.abs() < 0.01) {
        _hit.hitType = HitType.left;
      } else if (rightDistance < 0.01) {
        _hit.hitType = HitType.right;
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

    gestures[CustomScaleGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<CustomScaleGestureRecognizer>(
      () => CustomScaleGestureRecognizer(this, _hit),
      (CustomScaleGestureRecognizer instance) {
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

        return RawGestureDetector(
          gestures: gestures,
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: (widget.backcolor ?? Colors.black)
                .withOpacity(_pullDownBgColorScale),
            child: ClipRect(child: content),
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
      child: widget.heroTag != null
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
          delegate: CustomSingleChildLayoutDelegate(
            Size(posW, posH),
            Offset(posX, posY),
          ),
          child: Container(
            width: posW,
            height: posH,
            alignment: Alignment.center,
            child: Hero(
              tag: widget.heroTag!,
              child: _createImage(
                image: imageProvider,
                width: imageW,
                height: imageH,
              ),
            ),
          ),
        );
      }
      double x =
          _offset.dx + (_constraints!.maxWidth - _imageDefW) * _scale * 0.5;
      double y =
          _offset.dy + (_constraints!.maxHeight - _imageDefH) * _scale * 0.5;
      double width = _imageDefW * _scale;
      double height = _imageDefH * _scale;
      return CustomSingleChildLayout(
        delegate: CustomSingleChildLayoutDelegate(
          Size(width, height),
          Offset(x, y),
        ),
        child: Hero(
          tag: widget.heroTag!,
          child: _createImage(
            image: imageProvider,
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
    double width = (_constraints?.maxWidth ?? 0) * _pullDownContentScale;
    double height = (_constraints?.maxHeight ?? 0) * _pullDownContentScale;
    double dx = ((_constraints?.maxWidth ?? 0) - width) * 0.5 * _scale;
    double dy = ((_constraints?.maxHeight ?? 0) - height) * 0.5 * _scale;
    double x = _offset.dx + _pullDownContentOffset.dx + dx;
    double y = _offset.dy + _pullDownContentOffset.dy + dy;
    double scale = _scale * _pullDownContentScale;
    return Transform(
      transform: new Matrix4.identity()
        ..translate(x, y)
        ..scale(scale, scale, 1.0),
      child: _createImage(
        image: imageProvider,
      ),
    );
  }

  Image _createImage(
      {required ImageProvider image, double? width, double? height}) {
    return Image(
      image: image,
      gaplessPlayback: widget.gaplessPlayback ?? false,
      filterQuality: widget.filterQuality ?? FilterQuality.high,
      fit: BoxFit.contain,
      color: widget.imageColor,
      colorBlendMode: widget.imageColorBlendMode,
      width: width,
      height: height,
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
