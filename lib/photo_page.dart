import 'dart:async';
import 'package:flutter/material.dart';

typedef LoadingBuilder = Widget Function(
  BuildContext context,
  ImageChunkEvent event,
);

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

  ImageProviderInfo(this.imageProvider);
}

class PhotoPage extends StatefulWidget {
  PhotoPage({
    Key key,
    @required this.imageProvider,
    this.thumImageProvider,
    this.loadingBuilder,
    this.loadFailedChild,
    this.gaplessPlayback,
    this.filterQuality,
  }) : super(key: key);

  /// Given a [imageProvider] it resolves into an zoomable image widget using. It
  /// is required
  final ImageProvider imageProvider;

  final ImageProvider thumImageProvider;

  /// While [imageProvider] is not resolved, [loadingBuilder] is called by [PhotoPage]
  /// into the screen, by default it is a centered [CircularProgressIndicator]
  final LoadingBuilder loadingBuilder;

  /// Show loadFailedChild when the image failed to load
  final Widget loadFailedChild;

  /// This is used to continue showing the old image (`true`), or briefly show
  /// nothing (`false`), when the `imageProvider` changes. By default it's set
  /// to `false`.
  final bool gaplessPlayback;

  /// Quality levels for image filters.
  final FilterQuality filterQuality;

  @override
  State<StatefulWidget> createState() {
    return _PhotoPageState();
  }
}

class _PhotoPageState extends State<PhotoPage> {
  ImageProviderInfo _imageProviderInfo;
  ImageProviderInfo _thumImageProvideInfo;

  Size _imageSize;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset;
  double _oldScale;

  BoxConstraints _constraints;

  @override
  void initState() {
    super.initState();
    _imageProviderInfo = ImageProviderInfo(widget.imageProvider);
    _getImage(_imageProviderInfo);
    if (widget.thumImageProvider != null) {
      _thumImageProvideInfo = ImageProviderInfo(widget.thumImageProvider);
      _getImage(_thumImageProvideInfo);
    }
  }

  @override
  void didUpdateWidget(PhotoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<ImageInfo> _getImage(ImageProviderInfo providerInfo) {
    final Completer completer = Completer<ImageInfo>();
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
            providerInfo.status = _ImageLoadStatus.loading;
            providerInfo.imageChunkEvent = null;
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

  void _onDoubleTap() {
    if (_imageSize == null) return;
    if (_constraints == null) return;

    if (_scale != 1) {
      _scale = 1;
      _offset = Offset.zero;
      setState(() {});
      return;
    }

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
      _scale = imageMaxFitW / _constraints.maxWidth;
      _offset = Offset((_constraints.maxWidth - imageMaxFitW) * 0.5,
          (imageDefH - imageMaxFitH) * 0.5 * _scale);
    } else {
      imageDefH = _constraints.maxHeight;
      imageDefW = imageDefH * _imageSize.width / _imageSize.height;
      imageMaxFitW = _constraints.maxWidth;
      imageMaxFitH = imageMaxFitW * _imageSize.height / _imageSize.width;
      _scale = imageMaxFitH / _constraints.maxHeight;
      _offset = Offset((imageDefW - imageMaxFitW) * 0.5 * _scale,
          (_constraints.maxHeight - imageMaxFitH) * 0.5);
    }
    setState(() {});
  }

  void _onScaleStart(ScaleStartDetails details) {
    _oldScale = _scale;
    _normalizedOffset = (details.focalPoint - _offset) / _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _scale = (_oldScale * details.scale).clamp(1.0, double.infinity);
    _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
    // print('$_offset, $_scale');
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
            color: Colors.black,
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints,
      ImageProviderInfo providerInfo) {
    return FutureBuilder(
        future: _getImage(providerInfo),
        builder: (BuildContext context, AsyncSnapshot<ImageInfo> info) {
          if (info.hasData) {
            return _buildImage(constraints, providerInfo.imageProvider);
          } else {
            return _buildLoading(providerInfo.imageChunkEvent);
          }
        });
  }

  Widget _buildImage(BoxConstraints constraints, ImageProvider imageProvider) {
    return Container(
      color: Colors.red,
      constraints: const BoxConstraints(
        minWidth: double.maxFinite,
        minHeight: double.infinity,
      ),
      child: Transform(
        transform: new Matrix4.identity()
          ..translate(_offset.dx, _offset.dy)
          ..scale(_scale, _scale, 1.0),
        child: Image(
          image: imageProvider,
          gaplessPlayback: widget.gaplessPlayback ?? false,
          filterQuality: widget.filterQuality ?? FilterQuality.high,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildLoading(ImageChunkEvent imageChunkEvent) {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder(context, imageChunkEvent);
    }
    return Container();
  }

  Widget _buildLoadFailed() {
    return widget.loadFailedChild ?? Container();
  }
}
