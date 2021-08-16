import 'package:flutter/cupertino.dart';
import 'package:photo_browser/photo_page.dart';

class PhotoBrowser extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PhotoBrowserState();
  }

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

  PhotoBrowser({
    Key key,
    @required this.imageProvider,
    this.thumImageProvider,
    this.loadingBuilder,
    this.loadFailedChild,
    this.gaplessPlayback,
    this.filterQuality,
  }) : super(key: key);
}

class _PhotoBrowserState extends State<PhotoBrowser> {
  @override
  Widget build(BuildContext context) {
    return PhotoPage(
      imageProvider: widget.imageProvider,
      thumImageProvider: widget.thumImageProvider,
      loadFailedChild: widget.loadFailedChild,
      gaplessPlayback: widget.gaplessPlayback,
      filterQuality: widget.filterQuality,
    );
  }
}
