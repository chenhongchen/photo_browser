import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_browser/photo_page.dart';

typedef ImageProviderBuilder = ImageProvider Function(int index);
typedef StringBuilder = String Function(int index);
typedef PageCodeBuilder = Positioned Function(
  BuildContext,
  int curIndex,
  int totalNum,
);
typedef PositionsBuilder = List<Positioned> Function(
  BuildContext context,
  int curIndex,
  int totalNum,
);

enum HeroType {
  fade,
  scale,
}

class PhotoBrowser extends StatefulWidget {
  Future<dynamic> push(BuildContext context,
      {bool fullscreenDialog = true}) async {
    if (heroTagBuilder == null) {
      return await Navigator.of(context).push(CupertinoPageRoute(
          fullscreenDialog: fullscreenDialog,
          builder: (BuildContext context) {
            return this;
          }));
    }
    return heroPush(context);
  }

  Future<dynamic> heroPush(BuildContext context) async {
    return await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (BuildContext context, Animation animation,
            Animation secondaryAnimation) {
          //目标页面
          return this;
        },
        //动画时间
        transitionDuration: Duration(milliseconds: 400),
        //过渡动画构建
        transitionsBuilder: (
          BuildContext context,
          Animation animation,
          Animation secondaryAnimation,
          Widget child,
        ) {
          //渐变过渡动画
          return FadeTransition(
            // 透明度从 0.0-1.0
            opacity: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                //动画曲线规则，这里使用的是先快后慢
                curve: Curves.fastOutSlowIn,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _PhotoBrowserState();
  }

  final int itemCount;
  final int initIndex;
  final PhotoBrowerController controller;
  final HeroType heroType;
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
  final PositionsBuilder positionsBuilder;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final Color backcolor;
  final bool allowTapToPop;
  final bool allowSwipeDownToPop;
  final bool reverse;
  final PageController pageController;
  final ScrollPhysics scrollPhysics;
  final Axis scrollDirection;
  final ValueChanged<int> onPageChanged;

  //
  ImageProvider _initImageProvider;
  ImageProvider _initThumImageProvider;

  PhotoBrowser({
    Key key,
    @required this.itemCount,
    @required this.initIndex,
    this.controller,
    this.heroType = HeroType.fade,
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
    this.positionsBuilder,
    this.gaplessPlayback,
    this.filterQuality,
    this.backcolor,
    this.allowTapToPop = true,
    this.allowSwipeDownToPop = true,
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
  PageController _pageController;
  bool _isZoom = false;
  int _curPage = 0;
  double _lastDownY;
  bool _willPop = false;
  BoxConstraints _constraints;

  @override
  void initState() {
    widget.controller?._state = this;
    _curPage = widget.initIndex;
    _pageController =
        widget.pageController ?? PageController(initialPage: _curPage);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.pageController == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (
      BuildContext context,
      BoxConstraints constraints,
    ) {
      _constraints = constraints;
      if (widget.heroTagBuilder == null || widget.heroType == HeroType.fade) {
        return _buildPageView();
      } else {
        return Hero(
          tag: '${widget.heroTagBuilder(_curPage)}',
          child: _buildPageView(),
        );
      }
    });
  }

  Widget _buildPageView() {
    List<Widget> children = <Widget>[
      GestureDetector(
        onTap: widget.allowTapToPop ? _onTap : null,
        onVerticalDragDown: _isZoom == true || !widget.allowSwipeDownToPop
            ? null
            : _onVerticalDragDown,
        onVerticalDragUpdate: _isZoom == true || !widget.allowSwipeDownToPop
            ? null
            : _onVerticalDragUpdate,
        child: PageView.builder(
          reverse: widget.reverse,
          controller: _pageController,
          onPageChanged: (int index) {
            _curPage = index;
            setState(() {});
            widget.onPageChanged(index);
          },
          itemCount: widget.itemCount,
          itemBuilder: _buildItem,
          scrollDirection: widget.scrollDirection,
          physics:
              _isZoom ? NeverScrollableScrollPhysics() : widget.scrollPhysics,
        ),
      ),
      _buildPageCode(_curPage, widget.itemCount),
    ];
    if (widget.positionsBuilder != null) {
      children
          .addAll(widget.positionsBuilder(context, _curPage, widget.itemCount));
    }
    return Container(
      color: widget.backcolor ?? Colors.black,
      child: Stack(
        children: children,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    return PhotoPage(
      imageProvider: widget._getImageProvider(index),
      thumImageProvider: widget._getThumImageProvider(index),
      imageLoadSuccess: (ImageInfo imageInfo) {
        widget.controller.imageInfos[index] = imageInfo;
      },
      thumImageLoadSuccess: (ImageInfo imageInfo) {
        widget.controller.thumImageInfos[index] = imageInfo;
      },
      loadingBuilder: widget.loadingBuilder,
      loadFailedChild: widget.loadFailedChild,
      gaplessPlayback: widget.gaplessPlayback,
      filterQuality: widget.filterQuality,
      backcolor: Colors.transparent,
      heroType: widget.heroType,
      heroTag:
          widget.heroTagBuilder != null ? widget.heroTagBuilder(index) : null,
      willPop: _willPop,
      onZoomStatusChanged: (bool isZoom) {
        _isZoom = isZoom;
        setState(() {});
      },
    );
  }

  Positioned _buildPageCode(int curIndex, int totalNum) {
    if (widget.pageCodeBuild != null) {
      return widget.pageCodeBuild(context, curIndex + 1, totalNum);
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

  void _onTap() {
    _pop();
  }

  void _onVerticalDragDown(DragDownDetails details) {
    _lastDownY = details.localPosition.dy;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    var position = details.localPosition.dy;
    var detal = position - _lastDownY;
    if (detal > 50) {
      _pop();
    }
  }

  void _pop() {
    // 显示一页时，才允许pop
    if (((_pageController.position.pixels * 1000).toInt() %
            (_constraints.maxWidth * 1000).toInt()) !=
        0) return;
    _willPop = true;
    setState(() {});
    Navigator.of(context).pop();
  }
}

class PhotoBrowerController {
  _PhotoBrowserState _state;
  final Map<int, ImageInfo> imageInfos = Map<int, ImageInfo>();
  final Map<int, ImageInfo> thumImageInfos = Map<int, ImageInfo>();

  void pop() {
    _state?._pop();
  }

  setState(VoidCallback fn) {
    _state?.setState(fn);
  }

  dispose() {
    _state = null;
  }
}
