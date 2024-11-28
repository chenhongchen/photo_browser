export 'package:photos_browser/define.dart';
export 'package:photos_browser/pull_down_pop.dart';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos_browser/define.dart';
import 'package:photos_browser/pull_down_pop.dart';
import 'package:photos_browser/page/custom_page.dart';
import 'package:photos_browser/page/photo_page.dart';

typedef DisplayTypeBuilder = DisplayType Function(int index);
typedef ImageProviderBuilder = ImageProvider Function(int index);
typedef CustomChildBuilder = CustomChild Function(int index);
typedef PositionBuilder = Positioned Function(
  BuildContext context,
  int curIndex,
  int totalNum,
);
typedef PositionsBuilder = List<Positioned> Function(BuildContext context);

const String _notifyCurrentIndexChanged = 'currentIndexChanged';
const String _notifyPullDownScaleChanged = 'pullDownScaleChanged';

/// 显示类型
enum DisplayType {
  image, // 图片
  custom, // 自定义
}

class PhotoBrowser extends StatefulWidget {
  /// 弹出图片浏览器
  Future<dynamic> push(
    BuildContext context, {
    bool rootNavigator = true,
    bool fullscreenDialog = true,
    Duration? transitionDuration,
    Widget? page,
  }) async {
    if (routeType == RouteType.normal) {
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
        transitionDuration:
            transitionDuration ?? const Duration(milliseconds: 400),
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
  final PhotoBrowserController? controller;

  /// 路由类型，默认值：RouteType.fade
  final RouteType routeType;

  /// 允许缩小图片
  final bool allowShrinkPhoto;

  /// 设置每张图片飞行动画的tag
  final StringBuilder? heroTagBuilder;

  /// 设置每页显示的类型
  final DisplayTypeBuilder? displayTypeBuilder;

  /// 设置每张大图的imageProvider
  /// imageProviderBuilder、imageUrlBuilder二选一，必选
  final ImageProviderBuilder? imageProviderBuilder;

  /// 设置每张缩略图的imageProvider
  /// thumbImageProviderBuilder、thumbImageUrlBuilder二选一，可选
  final ImageProviderBuilder? thumbImageProviderBuilder;

  /// 设置每张大图的url
  final StringBuilder? imageUrlBuilder;

  /// 设置每张缩略图的url
  final StringBuilder? thumbImageUrlBuilder;

  /// 设置widget
  final CustomChildBuilder? customChildBuilder;

  /// 设置自定义图片加载指示器，为null则使用默认的
  final LoadingBuilder? loadingBuilder;

  /// 图片加载失败Widget
  final Widget? loadFailedChild;

  /// 设置自定义页码，为null则使用默认的
  final PositionBuilder? pageCodeBuild;

  /// 设置更多自定控件
  final PositionsBuilder? positions;

  /// 设置更多自定控件（页面索引变化会刷新里面的builder）
  final List<PositionBuilder>? positionBuilders;

  /// 设置背景色
  final Color? backcolor;

  /// 单击关闭功能开关
  final bool allowTapToPop;

  final BoolBuilder? allowTapToPopBuilder;

  /// 向下轻扫关闭功能开关（allowPullDownToPop 为）
  /// allowPullDownToPop 等于 true 则allowSwipeDownToPop设置无效
  final bool allowSwipeDownToPop;

  /// 下拉关闭功能开关
  final bool allowPullDownToPop;

  /// 滚动状态可否关闭
  final bool canPopWhenScrolling;

  /// 下拉关闭功能配置
  final PullDownPopConfig pullDownPopConfig;

  /// 显示左右翻页箭头按钮
  final bool showPageTurnBtn;

  final bool reverse;
  final Color? imageColor;
  final BlendMode? imageColorBlendMode;
  final bool? gaplessPlayback;
  final FilterQuality? filterQuality;
  final PageController? pageController;
  final ScrollPhysics? scrollPhysics;
  final Axis scrollDirection;
  final ValueChanged<int>? onPageChanged;

  PhotoBrowser({
    super.key,
    required this.itemCount,
    required this.initIndex,
    this.controller,
    this.routeType = RouteType.fade,
    this.allowShrinkPhoto = true,
    this.heroTagBuilder,
    this.displayTypeBuilder,
    this.imageProviderBuilder,
    this.thumbImageProviderBuilder,
    this.imageUrlBuilder,
    this.thumbImageUrlBuilder,
    this.customChildBuilder,
    this.loadingBuilder,
    this.loadFailedChild,
    this.pageCodeBuild,
    this.positions,
    this.positionBuilders,
    this.imageColor,
    this.imageColorBlendMode,
    this.gaplessPlayback,
    this.filterQuality,
    this.backcolor,
    this.allowTapToPop = true,
    this.allowTapToPopBuilder,
    bool allowSwipeDownToPop = true,
    this.allowPullDownToPop = false,
    this.canPopWhenScrolling = true,
    this.pullDownPopConfig = const PullDownPopConfig(),
    bool? showPageTurnBtn,
    this.reverse = false,
    this.pageController,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.onPageChanged,
  })  : allowSwipeDownToPop =
            (allowPullDownToPop == true) ? false : allowSwipeDownToPop,
        showPageTurnBtn = showPageTurnBtn ??
            (Platform.isIOS || Platform.isAndroid ? false : true),
        assert(imageProviderBuilder != null || imageUrlBuilder != null,
            'imageProviderBuilder,imageUrlBuilder can not all null');
}

class _PhotoBrowserState extends State<PhotoBrowser> {
  late PhotoBrowserController _browserController;
  late PageController _pageController;
  double? _lastDownY;
  bool _willPop = false;
  BoxConstraints? _constraints;
  PullDownPopStatus _pullDownPopStatus = PullDownPopStatus.none;

  double _pullDownScale = 1.0;

  double get pullDownScale => _pullDownScale;

  set pullDownScale(double value) {
    _pullDownScale = value;
    _browserController.notifyWithName(name: _notifyPullDownScaleChanged);
  }

  int _curIndex = 0;

  int get curIndex => _curIndex;

  set curIndex(int value) {
    _curIndex = value;
    _browserController.notifyWithName(name: _notifyCurrentIndexChanged);
  }

  @override
  void initState() {
    _browserController = widget.controller ?? PhotoBrowserController();
    _browserController._state = this;
    _curIndex = widget.initIndex;
    _pageController =
        widget.pageController ?? PageController(initialPage: widget.initIndex);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.pageController == null) {
      _pageController.dispose();
    }
    _browserController._state = null;
    if (widget.controller == null) {
      _browserController.dispose();
    }
    super.dispose();
  }

  void _setState(VoidCallback fn) {
    if (!mounted) {
      fn();
      return;
    }
    setState(fn);
  }

  ImageProvider _getImageProvider(int index) {
    ImageProvider? imageProvider;
    if (widget.imageProviderBuilder != null) {
      imageProvider = widget.imageProviderBuilder!(index);
    } else if (widget.imageUrlBuilder != null) {
      imageProvider = NetworkImage(widget.imageUrlBuilder!(index));
    }
    return imageProvider!;
  }

  ImageProvider? _getThumbImageProvider(int index) {
    ImageProvider? thumbImageProvider;
    if (widget.thumbImageProviderBuilder != null) {
      thumbImageProvider = widget.thumbImageProviderBuilder!(index);
    } else if (widget.thumbImageUrlBuilder != null) {
      thumbImageProvider = NetworkImage(widget.thumbImageUrlBuilder!(index));
    }
    return thumbImageProvider;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (
      BuildContext context,
      BoxConstraints constraints,
    ) {
      _constraints = constraints;
      return _buildContent();
    });
  }

  Widget _buildContent() {
    List<Widget> children = <Widget>[
      _buildBackColor(),
      _buildPageView(),
      _buildPageCode(),
      if (widget.showPageTurnBtn) _buildLeftArrow(),
      if (widget.showPageTurnBtn) _buildRightArrow(),
    ];
    if (widget.positions != null) {
      children.addAll(widget.positions!(context));
    }
    if (widget.positionBuilders != null) {
      for (PositionBuilder builder in widget.positionBuilders!) {
        children.add(PhotoBrowserProvider(
            controller: _browserController,
            notificationNames: const <String>[_notifyCurrentIndexChanged],
            builder: (BuildContext context) =>
                builder(context, _curIndex, widget.itemCount)));
      }
    }
    return Stack(children: children);
  }

  Widget _buildBackColor() {
    return PhotoBrowserProvider(
      controller: _browserController,
      notificationNames: const <String>[_notifyPullDownScaleChanged],
      builder: (BuildContext context) => Container(
          color:
              (widget.backcolor ?? Colors.black).withOpacity(_pullDownScale)),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      reverse: widget.reverse,
      controller: _pageController,
      onPageChanged: (int index) {
        curIndex = index;
        if (widget.onPageChanged != null) {
          widget.onPageChanged!(index);
        }
      },
      itemCount: widget.itemCount,
      itemBuilder: _buildItem,
      scrollDirection: widget.scrollDirection,
      physics: _pullDownPopStatus == PullDownPopStatus.pulling
          ? const NeverScrollableScrollPhysics()
          : widget.scrollPhysics,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    late Widget child;
    if (widget.displayTypeBuilder == null ||
        widget.displayTypeBuilder!(index) == DisplayType.image) {
      child = _buildPhotoPage(index);
    } else {
      child = _buildCustomPage(index);
    }
    bool allowTapToPop = widget.allowTapToPopBuilder != null
        ? widget.allowTapToPopBuilder!(index)
        : widget.allowTapToPop;
    return GestureDetector(
      onTap: allowTapToPop ? _onTap : null,
      onVerticalDragDown:
          !widget.allowSwipeDownToPop ? null : _onVerticalDragDown,
      onVerticalDragUpdate:
          !widget.allowSwipeDownToPop ? null : _onVerticalDragUpdate,
      child: Container(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  Widget _buildPhotoPage(int index) {
    return PhotoPage(
      imageProvider: _getImageProvider(index),
      thumbImageProvider: _getThumbImageProvider(index),
      loadingBuilder: widget.loadingBuilder,
      loadFailedChild: widget.loadFailedChild,
      backcolor: Colors.transparent,
      routeType: widget.routeType,
      heroTag: widget.heroTagBuilder != null && curIndex == index
          ? widget.heroTagBuilder!(index)
          : null,
      allowShrinkPhoto: widget.allowShrinkPhoto,
      willPop: _willPop,
      allowPullDownToPop: widget.allowPullDownToPop,
      pullDownPopConfig: widget.pullDownPopConfig,
      imageColor: widget.imageColor,
      imageColorBlendMode: widget.imageColorBlendMode,
      gaplessPlayback: widget.gaplessPlayback,
      filterQuality: widget.filterQuality,
      imageLoadSuccess: (ImageInfo imageInfo) {
        widget.controller?.imageInfo[index] = imageInfo;
      },
      thumbImageLoadSuccess: (ImageInfo imageInfo) {
        widget.controller?.thumbImageInfo[index] = imageInfo;
      },
      onScaleChanged: (double scale) {},
      pullDownPopChanged: (PullDownPopStatus status, double pullScale) {
        _pullDownPopStatus = status;
        pullDownScale = pullScale;
        if (status == PullDownPopStatus.canPop) {
          _pop();
        }
      },
    );
  }

  Widget _buildCustomPage(int index) {
    return CustomPage(
      child: widget.customChildBuilder!(index),
      backcolor: Colors.transparent,
      routeType: widget.routeType,
      heroTag: widget.heroTagBuilder != null && curIndex == index
          ? widget.heroTagBuilder!(index)
          : null,
      allowShrinkPhoto: widget.allowShrinkPhoto,
      willPop: _willPop,
      allowPullDownToPop: widget.allowPullDownToPop,
      pullDownPopConfig: widget.pullDownPopConfig,
      onScaleChanged: (double scale) {},
      pullDownPopChanged: (PullDownPopStatus status, double pullScale) {
        _pullDownPopStatus = status;
        pullDownScale = pullScale;
        if (status == PullDownPopStatus.canPop) {
          _pop();
        }
      },
    );
  }

  Widget _buildPageCode() {
    Positioned builder() {
      int showIndex = curIndex + 1;
      if (widget.pageCodeBuild != null) {
        return widget.pageCodeBuild!(context, showIndex, widget.itemCount);
      }
      return Positioned(
        right: 20,
        bottom: 20,
        child: Text(
          '$showIndex/${widget.itemCount}',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white.withAlpha(230),
            decoration: TextDecoration.none,
            shadows: const <Shadow>[
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

    return PhotoBrowserProvider(
      controller: _browserController,
      notificationNames: const <String>[_notifyCurrentIndexChanged],
      builder: (BuildContext context) => builder(),
    );
  }

  Widget _buildLeftArrow() {
    Positioned builder() {
      return Positioned(
        left: 20,
        top: MediaQuery.of(context).size.height * 0.5,
        child: GestureDetector(
          onTap: () {
            int index = curIndex <= 1 ? 0 : curIndex - 1;
            if (index == curIndex) return;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 333),
              curve: Curves.easeInOut,
            );
          },
          child: curIndex <= 0
              ? Container(width: 36, height: 36, color: Colors.transparent)
              : Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white.withAlpha(230),
                  size: 36,
                ),
        ),
      );
    }

    return PhotoBrowserProvider(
      controller: _browserController,
      notificationNames: const <String>[_notifyCurrentIndexChanged],
      builder: (BuildContext context) => builder(),
    );
  }

  Widget _buildRightArrow() {
    Positioned builder() {
      return Positioned(
        right: 20,
        top: MediaQuery.of(context).size.height * 0.5,
        child: GestureDetector(
          onTap: () {
            int index = curIndex >= widget.itemCount - 1
                ? widget.itemCount - 1
                : curIndex + 1;
            if (index == curIndex) return;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 333),
              curve: Curves.easeInOut,
            );
          },
          child: curIndex >= widget.itemCount - 1
              ? Container(width: 36, height: 36, color: Colors.transparent)
              : Icon(
                  Icons.keyboard_arrow_right,
                  color: Colors.white.withAlpha(230),
                  size: 36,
                ),
        ),
      );
    }

    return PhotoBrowserProvider(
      controller: _browserController,
      notificationNames: const <String>[_notifyCurrentIndexChanged],
      builder: (BuildContext context) => builder(),
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

  void _pop({bool canPop = true}) {
    // 滚动状态不允许pop处理
    if (!widget.canPopWhenScrolling &&
        (((_pageController.position.pixels * 1000).toInt() %
                (_constraints!.maxWidth * 1000).toInt()) !=
            0)) return;
    _willPop = true;
    setState(() {});
    if (canPop == true) Navigator.of(context).pop();
  }
}

class PhotoBrowserController with ChangeNotifier {
  String? notificationName;

  void notifyWithName({String? name}) {
    notificationName = name;
    super.notifyListeners();
  }

  @override
  void notifyListeners() {
    notificationName = null;
    super.notifyListeners();
  }

  bool _disposed = false;

  bool get disposed => _disposed;

  _PhotoBrowserState? _state;
  final Map<int, ImageInfo> imageInfo = <int, ImageInfo>{};
  final Map<int, ImageInfo> thumbImageInfo = <int, ImageInfo>{};

  static PhotoBrowserController? of(BuildContext context) {
    final PhotoBrowserProvider? provider =
        context.dependOnInheritedWidgetOfExactType<PhotoBrowserProvider>();
    return provider?.controller;
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
  }

  void pop() {
    _state?._pop();
  }

  setState(VoidCallback fn) {
    _state?._setState(fn);
  }

  PageController? get pageController => _state?._pageController;
}

class PhotoBrowserProvider extends InheritedWidget {
  final PhotoBrowserController controller;

  PhotoBrowserProvider({
    super.key,
    required this.controller,
    required WidgetBuilder builder,
    List<String>? notificationNames,
  }) : super(
            child: _NotificationListener(
          builder: builder,
          notificationNames: notificationNames,
        ));

  @override
  bool updateShouldNotify(covariant PhotoBrowserProvider oldWidget) {
    return controller != oldWidget.controller;
  }
}

class _NotificationListener extends StatefulWidget {
  final WidgetBuilder builder;
  final List<String>? notificationNames;

  const _NotificationListener({required this.builder, this.notificationNames});

  @override
  State<StatefulWidget> createState() {
    return _NotificationListenerState();
  }
}

class _NotificationListenerState extends State<_NotificationListener> {
  PhotoBrowserController? _controller;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 0), () {
      // ignore: use_build_context_synchronously
      _controller = PhotoBrowserController.of(context);
      _controller?.addListener(listener);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.removeListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  void listener() {
    if (_controller?.notificationName == null ||
        widget.notificationNames?.contains(_controller?.notificationName) ==
            true) {
      setState(() {});
    }
  }
}
