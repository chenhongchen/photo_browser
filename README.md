# photo_browser

Flutter plugin for photos browse.

## Demo

<img src="https://gitee.com/hongchenchen/test_photos_lib/raw/master/gif/photo_browser_0.gif" width="360" height="640" alt="demo"/><br/>

## Use it

```yaml
dependencies:
  photo_browser: 1.0.0
```

```dart
import 'package:photo_browser/photo_browser.dart';
```

### Creation and display of PhotoBrowser instance

```dart
Widget _buildCell(BuildContext context, int cellIndex) {
  return GestureDetector(
    onTap: () {
      // 弹出图片浏览器(默认单击或下划手势可关闭)
      PhotoBrowser(
        itemCount: _bigPhotos.length,
        initIndex: cellIndex,
        controller: _browerController,
        allowTapToPop: true,
        allowSwipeDownToPop: true,
        heroTagBuilder: (int index) {
          return _heroTags[index];
        }, // 飞行动画tag设置，为null则弹出动画为一般的push动画
        imageUrlBuilder: (int index) {
          return _bigPhotos[index];
        }, // 大图设置，如果想本地缓存图片可换imageProviderBuilder属性设置，然后传入带本地缓存功能的imageProvider
        thumImageUrlBuilder: (int index) {
          return _thumPhotos[index];
        }, // 缩略图设置，如果想本地缓存图片可换thumImageProviderBuilder属性设置，然后传入带本地缓存功能的imageProvider
        positionsBuilder: _positionsBuilder, // 可自定义Widget，如关闭按钮、保存按钮
        loadFailedChild: _failedChild(), // 加载失败
        onPageChanged: (int index) {},
      ).push(
        context,
        fullscreenDialog: true, //当heroTagBuilder属性为空时，该属性有效
      );
    },
    child: Hero(
      tag: _heroTags[cellIndex],
      child: Image.network(
        _thumPhotos[cellIndex],
        fit: BoxFit.cover,
      ),
    ),
  );
}
```

### Use of PhotoBrowerController

```dart
onTap: () {
  // 通过控制器pop退出，显示效果和默认单击退出效果一样
  _browerController.pop();
},
```

```dart
// 通过控制器，获取图片数据，转换为Uint8List，可以用于保存图片
ImageInfo imageInfo;
if (_browerController.imageInfos[curIndex] != null) {
  imageInfo = _browerController.imageInfos[curIndex];
} else if (_browerController.thumImageInfos[curIndex] != null) {
  imageInfo = _browerController.thumImageInfos[curIndex];
}
if (imageInfo == null) {
  return;
}

var byteData =
    await imageInfo.image.toByteData(format: ImageByteFormat.png);
Uint8List uint8list = byteData.buffer.asUint8List();
```

```dart
onTap: () {
  // 通过控制器，刷新PhotoBrowser
  _browerController.setState(() {});
},
```