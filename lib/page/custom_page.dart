import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:photo_browser/define.dart';
import 'package:photo_browser/page/page_mixin.dart';
import 'package:photo_browser/pull_down_pop.dart';
import 'package:photo_browser/photo_browser.dart';

class CustomChild {
  final Widget? child;

  /// 是否允许缩放
  final bool allowZoom;
  CustomChild({this.child, this.allowZoom = false});
}

class CustomPage extends StatefulWidget {
  CustomPage({
    Key? key,
    required this.child,
    this.backcolor,
    this.heroTag,
    this.routeType = RouteType.fade,
    this.allowShrinkPhoto = true,
    this.willPop = false,
    this.allowPullDownToPop = false,
    this.pullDownPopConfig = const PullDownPopConfig(),
    this.onScaleChanged,
    this.pullDownPopChanged,
  }) : super(key: key);

  final CustomChild child;
  final Color? backcolor;
  final String? heroTag;
  final RouteType routeType;
  final bool allowShrinkPhoto;
  final bool willPop;
  final bool allowPullDownToPop;
  final PullDownPopConfig pullDownPopConfig;
  final OnScaleChanged? onScaleChanged;
  final PullDownPopChanged? pullDownPopChanged;

  @override
  State<StatefulWidget> createState() {
    return _CustomPageState();
  }
}

class _CustomPageState extends State<CustomPage>
    with TickerProviderStateMixin, PageMixin {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    mInitSet(
      allowZoom: widget.child.allowZoom,
      allowShrinkPhoto: widget.allowShrinkPhoto,
      allowPullDownToPop: widget.allowPullDownToPop,
      pullDownPopChanged: widget.pullDownPopChanged,
      pullDownPopConfig: widget.pullDownPopConfig,
      onScaleChanged: widget.onScaleChanged,
    );
    mInitAnimationController(this);
  }

  @override
  void dispose() {
    mDisposeAnimationController();
    super.dispose();
  }

  @override
  bool mSetImageSize({BoxConstraints? constraints}) {
    if (_globalKey.currentContext?.size == null) return false;
    mImageSize = _globalKey.currentContext!.size;
    return super.mSetImageSize(constraints: constraints);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        SchedulerBinding.instance?.addPostFrameCallback((_) {
          mSetImageSize(constraints: constraints);
        });

        Widget content = _buildContent(constraints);

        return mRawGestureDetector(
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: (widget.backcolor ?? Colors.black)
                .withOpacity(mPullDownBgColorScale),
            child: ClipRect(child: widget.willPop ? content : content),
          ),
        );
      },
    );
  }

  Widget _buildContent(BoxConstraints constraints) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: double.maxFinite,
        minHeight: double.infinity,
      ),
      child:
          widget.heroTag != null ? _buildHeroImage() : _buildTransformImage(),
    );
  }

  Widget _buildHeroImage() {
    if (widget.willPop) {
      late double dx1, dy1, dx2, dy2, x, y, width, height, scale;
      double minW = min((mImageSize?.width ?? 0), mImageDefW);
      double minH = min((mImageSize?.height ?? 0), mImageDefH);
      if (mPullDownBgColorScale < 1) {
        scale = mPullDownContentScale * mScale;
        width = (mConstraints?.maxWidth ?? 0);
        height = (mConstraints?.maxHeight ?? 0);
        dx1 = (1 - mPullDownContentScale) * minW * 0.5;
        dy1 = (1 - mPullDownContentScale) * minH * 0.5;
        x = mPullDownContentOffset.dx + dx1;
        y = mPullDownContentOffset.dy + dy1;
      } else {
        scale = mScale;
        width = (mConstraints?.maxWidth ?? 0);
        height = (mConstraints?.maxHeight ?? 0);
        dx1 = (1 - mScale) * width * 0.5;
        dy1 = (1 - mScale) * height * 0.5;
        dx2 = (1 - mScale) * minW * 0.5;
        dy2 = (1 - mScale) * minH * 0.5;
        x = mOffset.dx - dx1 + dx2;
        y = mOffset.dy - dy1 + dy2;
      }
      return CustomSingleChildLayout(
        delegate: CustomSingleChildLayoutDelegate(
          Size(width, height),
          Offset(x, y),
        ),
        child: Center(
          child: Transform(
            transform: new Matrix4.identity()..scale(scale, scale, 1.0),
            child: Hero(
              tag: widget.heroTag!,
              child: Container(
                child: widget.child.child,
              ),
            ),
          ),
        ),
      );
    }
    return Hero(
      tag: widget.heroTag!,
      child: _buildTransformImage(),
    );
  }

  Widget _buildTransformImage() {
    return mBuildTransform(Center(
        child: Container(
      key: _globalKey,
      child: widget.child.child,
    )));
  }
}
