import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

/// 路由类型
enum RouteType {
  fade, // 淡入淡出
  normal, // 从右到左，或下到上
}

typedef StringBuilder = String Function(int index);
typedef BoolBuilder = bool Function(int index);
typedef OnScaleChanged = void Function(double scale);

class CustomSingleChildLayoutDelegate extends SingleChildLayoutDelegate {
  const CustomSingleChildLayoutDelegate(
    this.subjectSize,
    this.offset,
  );

  final Size subjectSize;
  final Offset offset;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return offset;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.tight(subjectSize);
  }

  @override
  bool shouldRelayout(CustomSingleChildLayoutDelegate oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomSingleChildLayoutDelegate &&
          runtimeType == other.runtimeType &&
          subjectSize == other.subjectSize &&
          offset == other.offset;

  @override
  int get hashCode => subjectSize.hashCode ^ offset.hashCode;
}

class CustomScaleGestureRecognizer extends ScaleGestureRecognizer {
  CustomScaleGestureRecognizer(
    Object debugOwner,
    this.hit,
  ) : super(debugOwner: debugOwner);

  final Hit hit;

  Map<int, Offset> _pointerLocations = <int, Offset>{};
  Offset? _initialFocalPoint;
  Offset? _currentFocalPoint;

  bool ready = true;

  @override
  void addAllowedPointer(event) {
    if (ready) {
      ready = false;
      _pointerLocations = <int, Offset>{};
    }
    super.addAllowedPointer(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    ready = true;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    _computeEvent(event);
    _updateDistances();
    _decideIfWeAcceptEvent(event);
    super.handleEvent(event);
  }

  void _computeEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (!event.synthesized) {
        _pointerLocations[event.pointer] = event.position;
      }
    } else if (event is PointerDownEvent) {
      _pointerLocations[event.pointer] = event.position;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerLocations.remove(event.pointer);
    }

    _initialFocalPoint = _currentFocalPoint;
  }

  void _updateDistances() {
    final int count = _pointerLocations.keys.length;
    Offset focalPoint = Offset.zero;
    for (int pointer in _pointerLocations.keys) {
      focalPoint += _pointerLocations[pointer]!;
    }
    _currentFocalPoint =
        count > 0 ? focalPoint / count.toDouble() : Offset.zero;
  }

  void _decideIfWeAcceptEvent(PointerEvent event) {
    if (event is! PointerMoveEvent) {
      return;
    }
    final move = _initialFocalPoint! - _currentFocalPoint!;
    if (hit.hitType == HitType.none ||
        (hit.hitType == HitType.left && move.dx > 0) ||
        (hit.hitType == HitType.right && move.dx < 0)) {
      resolve(GestureDisposition.accepted);
    }
  }
}

enum HitType {
  all,
  left,
  right,
  none,
}

class Hit {
  HitType hitType = HitType.all;
}
