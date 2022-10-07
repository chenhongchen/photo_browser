typedef PullDownPopChanged = void Function(
    PullDownPopStatus status, double pullScale);

/// 下拉关闭状态
enum PullDownPopStatus {
  none,
  pulling, // 下拉中
  canPop, // 可关闭
}

/// 下拉关闭配置
class PullDownPopConfig {
  /// 触发pop的下拉距离占全屏的比例
  /// 取值范围：(0.0, 1.0)
  final double triggerScale;

  /// 背景色最小透明度
  /// 取值范围：[0.0, 1.0]
  final double bgColorMinOpacity;

  /// 下拉时内容缩小的最小比例
  /// 取值范围：(0.0~1.0]
  final double contentMinScale;

  /// 下拉时图片大小、背景色透明度变化的快慢
  /// 取值范围：(0.0~1.0]，值越小变化越快
  final double changeRate;

  const PullDownPopConfig(
      {double? triggerScale,
      double? bgColorMinOpacity,
      double? contentMinScale,
      double? changeRate})
      : triggerScale =
            (triggerScale != null && triggerScale < 1 && triggerScale > 0)
                ? triggerScale
                : 0.1,
        bgColorMinOpacity = (bgColorMinOpacity != null &&
                bgColorMinOpacity <= 1 &&
                bgColorMinOpacity >= 0)
            ? bgColorMinOpacity
            : 0.0,
        contentMinScale = (contentMinScale != null &&
                contentMinScale <= 1 &&
                contentMinScale > 0)
            ? contentMinScale
            : 0.4,
        changeRate = (changeRate != null && changeRate <= 1 && changeRate > 0)
            ? changeRate
            : 0.25;
}
