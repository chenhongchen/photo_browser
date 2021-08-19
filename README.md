# photo_browser

Flutter plugin for photos browse.

## Demo

<img src="https://gitee.com/hongchenchen/test_photos_lib/raw/ff250fe8f51a4022c3edd5ac4fa3eda04089d281/gif/photo_browser.gif" width="360" height="640" alt="demo"/><br/>

```yaml
dependencies:
  photo_browser: 1.0.0
```

## Use it

```dart
import 'package:photo_browser/photo_browser.dart';
```

```dart
Widget _buildCell(BuildContext context, int cellIndex) {
    return GestureDetector(
      onTap: () {
        // 弹出图片浏览器(单击或下划手势可关闭)
        PhotoBrowser(
          itemCount: _photos.length,
          initIndex: cellIndex, // 设置初始显示页面
          heroTagBuilder: (int index) {
            return _photos[index];
          }, // 飞行动画tag设置，为null则弹出动画为一般的push动画
          imageUrlBuilder: (int index) {
            return _photos[index];
          }, // 大图设置，不能为空，如果想本地缓存图片可换imageProviderBuilder属性设置，然后传入带缓存功能的imageProvider
          thumImageUrlBuilder: (int index) {
            return _photos[index].replaceAll('big', 'thum');
          }, // 缩略图设置，可以为空，如果想本地缓存图片可换thumImageProviderBuilder属性设置，然后传入带缓存功能的imageProvider
          onPageChanged: (int index) {},
        ).show(
          context,
          fullscreenDialog: true, //当heroTagBuilder属性为空时，该属性有效
        );
      },
      child: Hero(
        tag: _photos[cellIndex],
        child: Image.network(
          _photos[cellIndex].replaceAll('big', 'thum'),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  ```