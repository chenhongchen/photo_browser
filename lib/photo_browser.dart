import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_browser/photo_page.dart';

typedef ImageProviderBuilder = ImageProvider Function(int index);
typedef StringBuilder = String Function(int index);
typedef PageCodeBuilder = Positioned Function(
  BuildContext context,
  int curIndex,
  int totalNum,
);
typedef PositionsBuilder = List<Positioned> Function(
  BuildContext context,
  int curIndex,
  int totalNum,
);

enum RouteType {
  fade, // 淡入淡出
  scale, // 比例放大
  normal, // 从右到左，或下到上
}

class PhotoBrowser extends StatefulWidget {
  Future<dynamic> push(
    BuildContext context, {
    bool rootNavigator = true,
    bool fullscreenDialog = true,
    Duration? transitionDuration,
    Widget? page,
  }) async {
    if (heroTagBuilder == null || routeType == RouteType.normal) {
      return await Navigator.of(context, rootNavigator: rootNavigator)
          .push(CupertinoPageRoute(
              fullscreenDialog: fullscreenDialog,
              builder: (BuildContext context) {
                return page ?? this;
              }));
    }
    return await _fadePush(
      context,
      rootNavigator: rootNavigator,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: transitionDuration,
      page: page,
    );
  }

  Future<dynamic> _fadePush(
    BuildContext context, {
    bool rootNavigator = true,
    bool fullscreenDialog = true,
    Duration? transitionDuration,
    Widget? page,
  }) async {
    return await Navigator.of(context, rootNavigator: rootNavigator).push(
      PageRouteBuilder(
        opaque: false,
        fullscreenDialog: fullscreenDialog,
        pageBuilder: (BuildContext context, Animation animation,
            Animation secondaryAnimation) {
          return page ?? this;
        },
        //动画时间
        transitionDuration: transitionDuration ?? Duration(milliseconds: 400),
        //过渡动画构建
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation secondaryAnimation,
          Widget child,
        ) {
          //渐变过渡动画
          return FadeTransition(
            // 透明度从 0.0-1.0
            opacity: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
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

  /// 图片总数
  final int itemCount;

  /// 初始索引
  final int initIndex;

  /// 控制器，用于给外部提供一些功能，如图片数据、pop、刷新相册浏览器状态
  final PhotoBrowerController? controller;

  /// 路由类型，默认值：RouteType.fade
  final RouteType routeType;

  /// 允许缩小图片
  final bool allowShrinkPhoto;

  /// 设置每张图片飞行动画的tag
  final StringBuilder? heroTagBuilder;

  /// 设置每张大图的imageProvider
  /// imageProviderBuilder、imageUrlBuilder二选一，必选
  final ImageProviderBuilder? imageProviderBuilder;

  /// 设置每张缩略图的imageProvider
  /// thumImageProviderBuilder、thumImageUrlBuilder二选一，可选
  final ImageProviderBuilder? thumImageProviderBuilder;

  /// 设置每张大图的url
  final StringBuilder? imageUrlBuilder;

  /// 设置每张缩略图的url
  final StringBuilder? thumImageUrlBuilder;

  /// 设置自定义图片加载指示器，为null则使用默认的
  final LoadingBuilder? loadingBuilder;

  /// 图片加载失败Widget
  final Widget? loadFailedChild;

  /// 设置自定义页码，为null则使用默认的
  final PageCodeBuilder? pageCodeBuild;

  /// 设置更多自定控件
  final PositionsBuilder? positionsBuilder;

  /// 设置背景色
  final Color? backcolor;

  /// 单击关闭功能开关
  final bool allowTapToPop;

  /// 向下轻扫关闭功能开关（allowDragDownToPop 为）
  /// allowDragDownToPop 等于 true 则allowSwipeDownToPop设置无效
  final bool allowSwipeDownToPop;

  /// 下拉关闭功能开关
  final bool allowDragDownToPop;

  /// 滚动状态可否关闭
  final bool canPopWhenScrolling;

  /// 下拉关闭功能配置
  final DragDownPopConfig dragDownPopConfig;

  final bool reverse;
  final bool? gaplessPlayback;
  final FilterQuality? filterQuality;
  final PageController? pageController;
  final ScrollPhysics? scrollPhysics;
  final Axis scrollDirection;
  final ValueChanged<int>? onPageChanged;

  //
  ImageProvider? _initImageProvider;
  ImageProvider? _initThumImageProvider;

  PhotoBrowser({
    Key? key,
    required this.itemCount,
    required this.initIndex,
    this.controller,
    this.routeType = RouteType.fade,
    this.allowShrinkPhoto = true,
    this.heroTagBuilder,
    this.imageProviderBuilder,
    this.thumImageProviderBuilder,
    this.imageUrlBuilder,
    this.thumImageUrlBuilder,
    this.loadingBuilder,
    this.loadFailedChild,
    this.pageCodeBuild,
    this.positionsBuilder,
    this.gaplessPlayback,
    this.filterQuality,
    this.backcolor,
    this.allowTapToPop = true,
    bool allowSwipeDownToPop = true,
    this.allowDragDownToPop = false,
    this.canPopWhenScrolling = true,
    this.dragDownPopConfig = const DragDownPopConfig(),
    this.reverse = false,
    this.pageController,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.onPageChanged,
  })  : this.allowSwipeDownToPop =
            (allowDragDownToPop == true) ? false : allowSwipeDownToPop,
        assert(imageProviderBuilder != null || imageUrlBuilder != null,
            'imageProviderBuilder,imageUrlBuilder can not all null'),
        super(key: key) {
    _initImageProvider = _getImageProvider(initIndex);
    _initThumImageProvider = _getThumImageProvider(initIndex);
  }

  ImageProvider _getImageProvider(int index) {
    if (index == initIndex && _initImageProvider != null) {
      return _initImageProvider!;
    }
    ImageProvider? imageProvider;
    if (imageProviderBuilder != null) {
      imageProvider = imageProviderBuilder!(index);
    } else if (imageUrlBuilder != null) {
      imageProvider = NetworkImage(imageUrlBuilder!(index));
    }
    return imageProvider!;
  }

  ImageProvider? _getThumImageProvider(int index) {
    if (index == initIndex && _initThumImageProvider != null) {
      return _initThumImageProvider!;
    }
    ImageProvider? thumImageProvider;
    if (thumImageProviderBuilder != null) {
      thumImageProvider = thumImageProviderBuilder!(index);
    } else if (thumImageUrlBuilder != null) {
      thumImageProvider = NetworkImage(thumImageUrlBuilder!(index));
    }
    return thumImageProvider;
  }
}

class _PhotoBrowserState extends State<PhotoBrowser> {
  late PageController _pageController;
  int _curPage = 0;
  double? _lastDownY;
  bool _willPop = false;
  BoxConstraints? _constraints;
  DragDownPopStatus _dragDownPopStatus = DragDownPopStatus.none;
  double _dragDownScale = 1.0;

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
      if (widget.heroTagBuilder == null ||
          widget.routeType != RouteType.scale) {
        return _buildContent();
      } else {
        return Hero(
          tag: '${widget.heroTagBuilder!(_curPage)}',
          child: _buildContent(),
        );
      }
    });
  }

  Widget _buildContent() {
    List<Widget> children = <Widget>[
      _buildPageView(),
      _buildPageCode(_curPage, widget.itemCount),
    ];
    if (widget.positionsBuilder != null) {
      children.addAll(
          widget.positionsBuilder!(context, _curPage, widget.itemCount));
    }
    return Container(
      color: (widget.backcolor ?? Colors.black).withOpacity(_dragDownScale),
      child: Stack(
        children: children,
      ),
    );
  }

  Widget _buildPageView() {
    return GestureDetector(
      onTap: widget.allowTapToPop ? _onTap : null,
      onVerticalDragDown:
          !widget.allowSwipeDownToPop ? null : _onVerticalDragDown,
      onVerticalDragUpdate:
          !widget.allowSwipeDownToPop ? null : _onVerticalDragUpdate,
      child: PageView.builder(
        reverse: widget.reverse,
        controller: _pageController,
        onPageChanged: (int index) {
          _curPage = index;
          setState(() {});
          if (widget.onPageChanged != null) {
            widget.onPageChanged!(index);
          }
        },
        itemCount: widget.itemCount,
        itemBuilder: _buildItem,
        scrollDirection: widget.scrollDirection,
        physics: _dragDownPopStatus == DragDownPopStatus.dragging
            ? NeverScrollableScrollPhysics()
            : widget.scrollPhysics,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    return PhotoPage(
      imageProvider: widget._getImageProvider(index),
      thumImageProvider: widget._getThumImageProvider(index),
      loadingBuilder: widget.loadingBuilder,
      loadFailedChild: widget.loadFailedChild,
      backcolor: Colors.transparent,
      routeType: widget.routeType,
      heroTag: widget.heroTagBuilder != null && _curPage == index
          ? widget.heroTagBuilder!(index)
          : null,
      allowShrinkPhoto: widget.allowShrinkPhoto,
      willPop: _willPop,
      allowDragDownToPop: widget.allowDragDownToPop,
      dragDownPopConfig: widget.dragDownPopConfig,
      gaplessPlayback: widget.gaplessPlayback,
      filterQuality: widget.filterQuality,
      imageLoadSuccess: (ImageInfo imageInfo) {
        widget.controller?.imageInfos[index] = imageInfo;
      },
      thumImageLoadSuccess: (ImageInfo imageInfo) {
        widget.controller?.thumImageInfos[index] = imageInfo;
      },
      onPhotoScaleChanged: (double scale) {},
      dragDownPopChanged: (DragDownPopStatus status, double dragScale) {
        _dragDownPopStatus = status;
        _dragDownScale = dragScale;
        if (status == DragDownPopStatus.canPop) {
          _pop();
        }
        setState(() {});
      },
    );
  }

  Positioned _buildPageCode(int curIndex, int totalNum) {
    if (widget.pageCodeBuild != null) {
      return widget.pageCodeBuild!(context, curIndex + 1, totalNum);
    }
    return Positioned(
      right: 20,
      bottom: 20,
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
    var detal = position - (_lastDownY ?? 0);
    if (detal > 50) {
      _pop();
    }
  }

  void _pop() {
    // 滚动状态不允许pop处理
    if (!widget.canPopWhenScrolling &&
        (((_pageController.position.pixels * 1000).toInt() %
                (_constraints!.maxWidth * 1000).toInt()) !=
            0)) return;
    _willPop = true;
    setState(() {});
    Navigator.of(context).pop();
  }
}

class PhotoBrowerController {
  _PhotoBrowserState? _state;
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
