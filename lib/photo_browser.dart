import 'package:flutter/cupertino.dart';
import 'package:photo_browser/photo_page.dart';

typedef ImageProviderBuilder = ImageProvider Function(int index);
typedef StringBuilder = String Function(int index);

class PhotoBrowser extends StatefulWidget {
  Future<dynamic> show(BuildContext context, {String heroTag}) async {
    this._initHeroTag = heroTag ?? this._initHeroTag;
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      pageBuilder: _fullScreenRoutePageBuilder,
    );
    await Navigator.of(context, rootNavigator: true).push(route);
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // chc 改 加动画
    return Hero(
      tag: _initHeroTag,
      child: _defaultRoutePageBuilder(context, animation, secondaryAnimation),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return this;
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _PhotoBrowserState();
  }

  final int itemCount;
  final StringBuilder heroTagBuilder;
  final ImageProviderBuilder imageProviderBuilder;
  final ImageProviderBuilder thumImageProviderBuilder;
  final StringBuilder imageUrlBuilder;
  final StringBuilder thumImageUrlBuilder;
  final StringBuilder imageAssetBuilder;
  final StringBuilder thumImageAssetBuilder;
  final LoadingBuilder loadingBuilder;
  final Widget loadFailedChild;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final Color backcolor;
  final bool reverse;
  final PageController pageController;
  final ScrollPhysics scrollPhysics;
  final Axis scrollDirection;
  final ValueChanged<int> onPageChanged;
  //
  final int initIndex;
  String _initHeroTag;
  ImageProvider _initImageProvider;
  ImageProvider _initThumImageProvider;

  PhotoBrowser({
    Key key,
    @required this.itemCount,
    @required this.initIndex,
    this.heroTagBuilder,
    this.imageProviderBuilder,
    this.thumImageProviderBuilder,
    this.imageUrlBuilder,
    this.thumImageUrlBuilder,
    this.imageAssetBuilder,
    this.thumImageAssetBuilder,
    this.loadingBuilder,
    this.loadFailedChild,
    this.gaplessPlayback,
    this.filterQuality,
    this.backcolor,
    this.reverse = false,
    this.pageController,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.onPageChanged,
  })  : assert(itemCount != null),
        assert(imageProviderBuilder != null ||
            imageUrlBuilder != null ||
            imageAssetBuilder != null),
        super(key: key) {
    _initImageProvider = _getImageProvider(initIndex);
    _initThumImageProvider = _getThumImageProvider(initIndex);
  }

  ImageProvider _getImageProvider(int index) {
    if (index == initIndex && _initImageProvider != null) {
      return _initImageProvider;
    }
    ImageProvider imageProvider;
    if (imageProviderBuilder != null) {
      imageProvider = imageProviderBuilder(index);
    } else if (imageUrlBuilder != null) {
      imageProvider = NetworkImage(imageUrlBuilder(index));
    } else {
      imageProvider = AssetImage(imageAssetBuilder(index));
    }
    return imageProvider;
  }

  ImageProvider _getThumImageProvider(int index) {
    if (index == initIndex && _initThumImageProvider != null) {
      return _initThumImageProvider;
    }
    ImageProvider thumImageProvider;
    if (thumImageProviderBuilder != null) {
      thumImageProvider = thumImageProviderBuilder(index);
    } else if (thumImageUrlBuilder != null) {
      thumImageProvider = NetworkImage(thumImageUrlBuilder(index));
    } else {
      thumImageProvider = AssetImage(thumImageAssetBuilder(index));
    }
    return thumImageProvider;
  }
}

class _PhotoBrowserState extends State<PhotoBrowser> {
  PageController _controller;
  bool _isZoom = false;

  @override
  void initState() {
    _controller = widget.pageController ?? PageController();
    super.initState();
  }

  @override
  void dispose() {
    if (widget.pageController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
      child: PageView.builder(
        reverse: widget.reverse,
        controller: _controller,
        onPageChanged: widget.onPageChanged,
        itemCount: widget.itemCount,
        itemBuilder: _buildItem,
        scrollDirection: widget.scrollDirection,
        physics:
            _isZoom ? NeverScrollableScrollPhysics() : widget.scrollPhysics,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    return PhotoPage(
      imageProvider: widget._getImageProvider(index),
      thumImageProvider: widget._getThumImageProvider(index),
      loadFailedChild: widget.loadFailedChild,
      gaplessPlayback: widget.gaplessPlayback,
      filterQuality: widget.filterQuality,
      backcolor: widget.backcolor,
      onZoomStatusChanged: (bool isZoom) {
        _isZoom = isZoom;
        setState(() {});
      },
    );
  }
}
