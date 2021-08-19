import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_browser/photo_page.dart';

typedef ImageProviderBuilder = ImageProvider Function(int index);
typedef StringBuilder = String Function(int index);
typedef PageCodeBuilder = Positioned Function(int curIndex, int totalNum);

class PhotoBrowser extends StatefulWidget {
  Future<dynamic> show(BuildContext context,
      {bool fullscreenDialog = true}) async {
    if (heroTagBuilder == null) {
      return await Navigator.of(context).push(CupertinoPageRoute(
          fullscreenDialog: fullscreenDialog,
          builder: (BuildContext context) {
            return this;
          }));
    }

    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      pageBuilder: _defaultRoutePageBuilder,
      opaque: false,
    );
    return await Navigator.of(context, rootNavigator: true).push(route);
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
  final PageCodeBuilder pageCodeBuild;
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
    this.pageCodeBuild,
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
    } else if (imageAssetBuilder != null) {
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
    } else if (thumImageAssetBuilder != null) {
      thumImageProvider = AssetImage(thumImageAssetBuilder(index));
    }
    return thumImageProvider;
  }
}

class _PhotoBrowserState extends State<PhotoBrowser> {
  PageController _controller;
  bool _isZoom = false;
  int _curPage = 0;
  double _lastDownY;

  @override
  void initState() {
    _curPage = widget.initIndex;
    _controller =
        widget.pageController ?? PageController(initialPage: _curPage);
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
    return widget.heroTagBuilder == null
        ? _buildPageView()
        : Hero(
            tag: '${widget.heroTagBuilder(_curPage)}',
            child: _buildPageView(),
          );
  }

  Widget _buildPageView() {
    return Container(
      color: widget.backcolor ?? Colors.black,
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            onVerticalDragDown: _isZoom == true ? null : _onVerticalDragDown,
            onVerticalDragUpdate:
                _isZoom == true ? null : _onVerticalDragUpdate,
            child: PageView.builder(
              reverse: widget.reverse,
              controller: _controller,
              onPageChanged: (int index) {
                _curPage = index;
                setState(() {});
                widget.onPageChanged(index);
              },
              itemCount: widget.itemCount,
              itemBuilder: _buildItem,
              scrollDirection: widget.scrollDirection,
              physics: _isZoom
                  ? NeverScrollableScrollPhysics()
                  : widget.scrollPhysics,
            ),
          ),
          _buildPageCode(_curPage, widget.itemCount),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    return PhotoPage(
      imageProvider: widget._getImageProvider(index),
      thumImageProvider: widget._getThumImageProvider(index),
      loadingBuilder: widget.loadingBuilder,
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

  Positioned _buildPageCode(int curIndex, int totalNum) {
    if (widget.pageCodeBuild != null) {
      return widget.pageCodeBuild(curIndex + 1, totalNum);
    }
    return Positioned(
      right: 15,
      bottom: 15,
      child: Text(
        '${curIndex + 1}/$totalNum',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Colors.white.withAlpha(230),
          decoration: TextDecoration.none,
          shadows: <Shadow>[
            Shadow(
              offset: Offset(1.0, 1.0),
              blurRadius: 3.0,
              color: Colors.black,
            ),
            Shadow(
              offset: Offset(1.0, 1.0),
              blurRadius: 8.0,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  _onVerticalDragDown(DragDownDetails details) {
    _lastDownY = details.localPosition.dy;
  }

  _onVerticalDragUpdate(DragUpdateDetails details) async {
    var position = details.localPosition.dy;
    var detal = position - _lastDownY;
    if (detal > 50) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
