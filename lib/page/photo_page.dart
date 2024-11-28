import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photos_browser/define.dart';
import 'package:photos_browser/page/page_mixin.dart';
import 'package:photos_browser/pull_down_pop.dart';

typedef LoadingBuilder = Widget Function(
  BuildContext context,
  double progress,
);

typedef ImageLoadSuccess = void Function(ImageInfo imageInfo);

enum ImageLoadStatus {
  loading,
  failed,
  completed,
}

/// ImageProvider信息
class ImageProviderInfo {
  ImageProvider imageProvider;
  Size? imageSize;
  ImageLoadStatus? status;
  ImageChunkEvent? imageChunkEvent;
  ImageInfo? imageInfo;

  ImageProviderInfo(this.imageProvider);
}

class PhotoPage extends StatefulWidget {
  const PhotoPage({
    super.key,
    required this.imageProvider,
    this.thumbImageProvider,
    this.loadingBuilder,
    this.loadFailedChild,
    this.backcolor = Colors.black,
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
    this.thumbImageLoadSuccess,
    this.onScaleChanged,
    this.pullDownPopChanged,
  });

  /// 大图的imageProvider
  final ImageProvider imageProvider;

  /// 缩略图的imageProvider
  final ImageProvider? thumbImageProvider;

  /// 设置自定义图片加载指示器，为null则使用默认的
  final LoadingBuilder? loadingBuilder;

  /// 图片加载失败Widget
  final Widget? loadFailedChild;

  /// 设置背景色
  final Color backcolor;

  /// 飞行动画的tag
  final String? heroTag;

  /// 路由类型，默认值：RouteType.fade
  final RouteType routeType;

  /// 允许缩小图片
  final bool allowShrinkPhoto;

  final bool willPop;

  /// 下拉关闭功能开关
  final bool allowPullDownToPop;

  /// 下拉关闭功能配置
  final PullDownPopConfig pullDownPopConfig;

  /// 大图加载完成回调
  final ImageLoadSuccess? imageLoadSuccess;

  /// 缩略图加载完成回调
  final ImageLoadSuccess? thumbImageLoadSuccess;

  /// 比例变化回调
  final OnScaleChanged? onScaleChanged;

  /// 下拉关闭状态变化回调
  final PullDownPopChanged? pullDownPopChanged;

  final Color? imageColor;
  final BlendMode? imageColorBlendMode;
  final bool? gaplessPlayback;
  final FilterQuality? filterQuality;

  @override
  State<StatefulWidget> createState() {
    return _PhotoPageState();
  }
}

class _PhotoPageState extends State<PhotoPage>
    with TickerProviderStateMixin, PageMixin {
  late ImageProviderInfo _imageProviderInfo;
  ImageProviderInfo? _thumbImageProvideInfo;

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
    _getThumbImageInfo();
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

  void _getThumbImageInfo() async {
    if (widget.thumbImageProvider == null) return;
    _thumbImageProvideInfo = ImageProviderInfo(widget.thumbImageProvider!);
    var imageInfo = await _getImage(_thumbImageProvideInfo!);
    if (widget.thumbImageLoadSuccess != null) {
      widget.thumbImageLoadSuccess!(imageInfo);
    }
  }

  Future<ImageInfo> _getImage(ImageProviderInfo providerInfo) async {
    if (providerInfo.imageInfo != null) return providerInfo.imageInfo!;
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    providerInfo.status = ImageLoadStatus.loading;
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
          setupCallback() {
            providerInfo.imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
            providerInfo.status = ImageLoadStatus.completed;
            providerInfo.imageChunkEvent = null;
            providerInfo.imageInfo = info;
            mImageSize = providerInfo.imageSize;
            mSetImageSize();
          }

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
        providerInfo.status = ImageLoadStatus.failed;
      });
      FlutterError.reportError(
        FlutterErrorDetails(exception: exception, stack: stackTrace),
      );
    });
    stream.addListener(listener);
    completer.future.then((_) {
      stream.removeListener(listener);
      providerInfo.status = ImageLoadStatus.completed;
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (_imageProviderInfo.status == ImageLoadStatus.failed &&
        (_thumbImageProvideInfo == null ||
            _thumbImageProvideInfo?.status == ImageLoadStatus.failed)) {
      return _buildLoadFailed();
    }

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        mSetImageSize(constraints: constraints);
        Widget content;
        if (_thumbImageProvideInfo == null ||
            _imageProviderInfo.status == ImageLoadStatus.completed) {
          content = _buildContent(context, constraints, _imageProviderInfo);
        } else {
          content =
              _buildContent(context, constraints, _thumbImageProvideInfo!);
        }

        Color backColor = widget.backcolor == Colors.transparent
            ? Colors.transparent
            : widget.backcolor.withOpacity(mPullDownBgColorScale);
        return mRawGestureDetector(
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: backColor,
            child: ClipRect(child: content),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints,
      ImageProviderInfo providerInfo) {
    return Stack(
      children: [
        Positioned.fill(
            child: _buildImage(constraints, providerInfo.imageProvider)),
        if (providerInfo.status == ImageLoadStatus.loading)
          Positioned.fill(
            child: _buildLoading(imageChunkEvent: providerInfo.imageChunkEvent),
          ),
      ],
    );
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
      double x =
          mOffset.dx + (mConstraints!.maxWidth - mImageDefW) * mScale * 0.5;
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
      child: SizedBox(
        width: 40.0,
        height: 40.0,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor:
              AlwaysStoppedAnimation<Color>(Colors.white.withAlpha(230)),
          value: progress,
        ),
      ),
    );
  }

  Widget _buildLoadFailed() {
    return widget.loadFailedChild ?? Container();
  }
}
