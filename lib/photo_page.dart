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

class PhotoView extends StatefulWidget {
  PhotoView({
    Key key,
    @required this.heroImageProvider,
    this.imageProvider,
    this.loadingBuilder,
    this.loadFailedChild,
    this.gaplessPlayback,
    this.filterQuality,
  }) : super(key: key);

  /// Given a [imageProvider] it resolves into an zoomable image widget using. It
  /// is required
  final ImageProvider imageProvider;

  final ImageProvider heroImageProvider;

  /// While [imageProvider] is not resolved, [loadingBuilder] is called by [PhotoView]
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
    return _PhotoViewState();
  }
}

class ImageProviderInfo {
  ImageProvider imageProvider;
  Size childSize;
  _ImageLoadStatus status;
  ImageChunkEvent imageChunkEvent;

  ImageProviderInfo(this.imageProvider);
}

class _PhotoViewState extends State<PhotoView> {
  ImageProviderInfo _imageProviderInfo;
  ImageProviderInfo _heroImageProvideInfo;

  @override
  void initState() {
    super.initState();
    if (widget.imageProvider != null) {
      _imageProviderInfo = ImageProviderInfo(widget.imageProvider);
      _getImage(_imageProviderInfo);
    }
    _heroImageProvideInfo = ImageProviderInfo(widget.heroImageProvider);
    _getImage(_heroImageProvideInfo);
  }

  @override
  void didUpdateWidget(PhotoView oldWidget) {
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
            providerInfo.childSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
            providerInfo.status = _ImageLoadStatus.loading;
            providerInfo.imageChunkEvent = null;
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

  @override
  Widget build(BuildContext context) {
    if (_heroImageProvideInfo.status == _ImageLoadStatus.failed &&
        (_imageProviderInfo == null ||
            _imageProviderInfo?.status == _ImageLoadStatus.failed)) {
      return _buildLoadFailed();
    }

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        if (_imageProviderInfo?.status == _ImageLoadStatus.completed) {
          return _buildImage(context, constraints, _imageProviderInfo);
        } else {
          return _buildImage(context, constraints, _heroImageProvideInfo);
        }
      },
    );
  }

  Widget _buildImage(BuildContext context, BoxConstraints constraints,
      ImageProviderInfo providerInfo) {
    return FutureBuilder(
        future: _getImage(providerInfo),
        builder: (BuildContext context, AsyncSnapshot<ImageInfo> info) {
          if (info.hasData) {
            return _buildChild(providerInfo.imageProvider);
          } else {
            return _buildLoading(providerInfo.imageChunkEvent);
          }
        });
  }

  Widget _buildChild(ImageProvider imageProvider) {
    return Image(
      image: imageProvider,
      gaplessPlayback: widget.gaplessPlayback ?? false,
      filterQuality: widget.filterQuality,
      width: MediaQuery.of(context).size.width,
      fit: BoxFit.contain,
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
