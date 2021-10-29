import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_browser/define.dart';
import 'package:photo_browser/page_mixin.dart';
import 'package:photo_browser/photo_browser.dart';
import 'package:photo_browser/pull_down_pop.dart';

typedef LoadingBuilder = Widget Function(
  BuildContext context,
  double progress,
);

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

class _PhotoPageState extends State<PhotoPage>
    with TickerProviderStateMixin, PageMixin {
  late ImageProviderInfo _imageProviderInfo;
  ImageProviderInfo? _thumImageProvideInfo;

  @override
  void initState() {
    super.initState();
    mInitSet(
      allowShrinkPhoto: widget.allowShrinkPhoto,
      allowPullDownToPop: widget.allowPullDownToPop,
      pullDownPopChanged: widget.pullDownPopChanged,
      pullDownPopConfig: widget.pullDownPopConfig,
      onScaleChanged: widget.onScaleChanged,
    );
    mInitAnimationController(this);

    _getImageInfo();
    _getThumImageInfo();
  }

  @override
  void dispose() {
    mDisposeAnimationController();
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
            mImageSize = providerInfo.imageSize;
            mSetImageSize();
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
        mConstraints = constraints;
        mSetImageSize();
        Widget content;
        if (_thumImageProvideInfo == null ||
            _imageProviderInfo.status == _ImageLoadStatus.completed) {
          content = _buildContent(context, constraints, _imageProviderInfo);
        } else {
          content = _buildContent(context, constraints, _thumImageProvideInfo!);
        }

        return mRawGestureDetector(
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: (widget.backcolor ?? Colors.black)
                .withOpacity(mPullDownBgColorScale),
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
      if (mPullDownBgColorScale < 1) {
        double posW = (mConstraints?.maxWidth ?? 0) * mPullDownContentScale;
        double posH = (mConstraints?.maxHeight ?? 0) * mPullDownContentScale;
        double dx = ((mConstraints?.maxWidth ?? 0) - posW) * 0.5;
        double dy = ((mConstraints?.maxHeight ?? 0) - posH) * 0.5;
        double posX = mPullDownContentOffset.dx + dx;
        double posY = mPullDownContentOffset.dy + dy;
        double imageW = mImageDefW * mScale * mPullDownContentScale;
        double imageH = mImageDefH * mScale * mPullDownContentScale;
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
      double x = mOffset.dx + (mConstraints!.maxWidth - mImageDefW) * mScale * 0.5;
      double y =
          mOffset.dy + (mConstraints!.maxHeight - mImageDefH) * mScale * 0.5;
      double width = mImageDefW * mScale;
      double height = mImageDefH * mScale;
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
    return mBuildTransform(_createImage(
      image: imageProvider,
    ));
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
