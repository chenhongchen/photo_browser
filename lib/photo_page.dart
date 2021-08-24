import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_browser/photo_browser.dart';

typedef LoadingBuilder = Widget Function(
  BuildContext context,
  double progress,
);

typedef OnPhotoScaleChanged = void Function(double scale);

typedef ImageLoadSuccess = void Function(ImageInfo imageInfo);

enum _ImageLoadStatus {
  loading,
  failed,
  completed,
}

class ImageProviderInfo {
  ImageProvider imageProvider;
  Size imageSize;
  _ImageLoadStatus status;
  ImageChunkEvent imageChunkEvent;
  ImageInfo imageInfo;

  ImageProviderInfo(this.imageProvider);
}

class PhotoPage extends StatefulWidget {
  PhotoPage({
    Key key,
    @required this.imageProvider,
    this.thumImageProvider,
    this.loadingBuilder,
    this.loadFailedChild,
    this.backcolor,
    this.heroTag,
    this.heroType = HeroType.fade,
    this.allowShrinkPhoto = true,
    this.willPop = false,
    this.gaplessPlayback,
    this.filterQuality,
    this.imageLoadSuccess,
    this.thumImageLoadSuccess,
    this.onPhotoScaleChanged,
  }) : super(key: key);

  final ImageProvider imageProvider;
  final ImageProvider thumImageProvider;
  final LoadingBuilder loadingBuilder;
  final Widget loadFailedChild;
  final Color backcolor;
  final String heroTag;
  final HeroType heroType;
  final bool allowShrinkPhoto;
  final bool willPop;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final ImageLoadSuccess imageLoadSuccess;
  final ImageLoadSuccess thumImageLoadSuccess;
  final OnPhotoScaleChanged onPhotoScaleChanged;

  @override
  State<StatefulWidget> createState() {
    return _PhotoPageState();
  }
}

class _PhotoPageState extends State<PhotoPage> with TickerProviderStateMixin {
  ImageProviderInfo _imageProviderInfo;
  ImageProviderInfo _thumImageProvideInfo;

  Size _imageSize;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset = Offset.zero;
  double _oldScale = 1.0;

  BoxConstraints _constraints;

  AnimationController _scaleAnimationController;
  Animation<double> _scaleAnimation;

  AnimationController _positionAnimationController;
  Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _scaleAnimationController =
        AnimationController(duration: Duration(milliseconds: 120), vsync: this)
          ..addListener(_handleScaleAnimation);
    _positionAnimationController =
        AnimationController(duration: Duration(milliseconds: 120), vsync: this)
          ..addListener(_handlePositionAnimate);

    _getImageInfo();
    _getThumImageInfo();
  }

  @override
  void dispose() {
    _scaleAnimationController.removeListener(_handleScaleAnimation);
    _scaleAnimationController.dispose();
    _positionAnimationController.removeListener(_handlePositionAnimate);
    _positionAnimationController.dispose();
    super.dispose();
  }

  void _getImageInfo() async {
    _imageProviderInfo = ImageProviderInfo(widget.imageProvider);
    var imageInfo = await _getImage(_imageProviderInfo);
    if (widget.imageLoadSuccess != null) {
      widget.imageLoadSuccess(imageInfo);
    }
  }

  void _getThumImageInfo() async {
    if (widget.thumImageProvider == null) return;
    _thumImageProvideInfo = ImageProviderInfo(widget.thumImageProvider);
    var imageInfo = await _getImage(_thumImageProvideInfo);
    if (widget.thumImageLoadSuccess != null) {
      widget.thumImageLoadSuccess(imageInfo);
    }
  }

  Future<ImageInfo> _getImage(ImageProviderInfo providerInfo) async {
    if (providerInfo.imageInfo != null) return providerInfo.imageInfo;
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

  void _handleScaleAnimation() {
    _scale = _scaleAnimation.value;
    setState(() {});
  }

  void _handlePositionAnimate() {
    _offset = _positionAnimation.value;
    setState(() {});
  }

  void _onDoubleTap() {
    if (_imageSize == null) return;
    if (_constraints == null) return;
    if (_constraints.maxWidth == 0 || _constraints.maxHeight == 0) return;
    if (_imageSize.width == 0 || _imageSize.height == 0) return;

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
      double imageDefW = 0;
      double imageDefH = 0;
      double imageMaxFitW = 0;
      double imageMaxFitH = 0;
      if (_imageSize.width / _imageSize.height >
          _constraints.maxWidth / _constraints.maxHeight) {
        imageDefW = _constraints.maxWidth;
        imageDefH = imageDefW * _imageSize.height / _imageSize.width;
        imageMaxFitH = _constraints.maxHeight;
        imageMaxFitW = imageMaxFitH * _imageSize.width / _imageSize.height;
        newScale = imageMaxFitW / _constraints.maxWidth;
        newOffset = Offset((_constraints.maxWidth - imageMaxFitW) * 0.5,
            (imageDefH - imageMaxFitH) * 0.5 * newScale);
      } else {
        imageDefH = _constraints.maxHeight;
        imageDefW = imageDefH * _imageSize.width / _imageSize.height;
        imageMaxFitW = _constraints.maxWidth;
        imageMaxFitH = imageMaxFitW * _imageSize.height / _imageSize.width;
        newScale = imageMaxFitH / _constraints.maxHeight;
        newOffset = Offset((imageDefW - imageMaxFitW) * 0.5 * newScale,
            (_constraints.maxHeight - imageMaxFitH) * 0.5);
      }
    }
    if (widget.onPhotoScaleChanged != null) {
      widget.onPhotoScaleChanged(newScale);
    }
    _animateScale(oldScale, newScale);
    _animatePosition(oldOffset, newOffset);
    _positionAnimationController.forward();
    _scaleAnimationController.forward();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _oldScale = _scale;
    _normalizedOffset = (details.focalPoint - _offset) / _scale;
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
            (_constraints.maxWidth - _constraints.maxWidth * _scale) * 0.5,
            (_constraints.maxHeight - _constraints.maxHeight * _scale) * 0.5);
        _normalizedOffset = (details.focalPoint - _offset) / _scale;
      }
    }
    if (widget.onPhotoScaleChanged != null && _scale != _oldScale) {
      widget.onPhotoScaleChanged(_scale);
    }
    setState(() {});
  }

  void _onScaleEnd(ScaleEndDetails details) {}

  Offset _clampOffset(Offset offset) {
    final Size size = context.size; //容器的大小
    final Offset minOffset =
        new Offset(size.width, size.height) * (1.0 - _scale);
    return new Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  @override
  Widget build(BuildContext context) {
    if (_imageProviderInfo.status == _ImageLoadStatus.failed &&
        (_thumImageProvideInfo == null ||
            _thumImageProvideInfo?.status == _ImageLoadStatus.failed)) {
      return _buildLoadFailed();
    }

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        _constraints = constraints;
        Widget content;
        if (_thumImageProvideInfo == null ||
            _imageProviderInfo?.status == _ImageLoadStatus.completed) {
          content = _buildContent(context, constraints, _imageProviderInfo);
        } else {
          content = _buildContent(context, constraints, _thumImageProvideInfo);
        }
        return GestureDetector(
          onDoubleTap: _onDoubleTap,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: widget.backcolor ?? Colors.black,
            child: content,
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
      child: widget.heroTag != null && widget.heroType == HeroType.fade
          ? _buildHeroImage(imageProvider)
          : _buildTransformImage(imageProvider),
    );
  }

  Widget _buildHeroImage(ImageProvider imageProvider) {
    return (widget.willPop && _scale <= 1)
        ? Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _constraints.maxWidth * _scale,
                maxHeight: _constraints.maxHeight * _scale,
              ),
              child: Hero(
                tag: widget.heroTag,
                child: Image(
                  image: imageProvider,
                  gaplessPlayback: widget.gaplessPlayback ?? false,
                  filterQuality: widget.filterQuality ?? FilterQuality.high,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          )
        : Hero(
            tag: widget.heroTag,
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

  Widget _buildLoading({ImageChunkEvent imageChunkEvent}) {
    double progress = 0.0;
    if (imageChunkEvent?.cumulativeBytesLoaded != null &&
        imageChunkEvent?.expectedTotalBytes != null) {
      progress = imageChunkEvent.cumulativeBytesLoaded /
          imageChunkEvent.expectedTotalBytes;
    }
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder(context, progress);
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
