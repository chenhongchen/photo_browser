# photo_browser

PhotoBrowser is a zoomable picture browsing plugin that supports thumbnails and provides picture data that you can use to download to your local album.

## Demo

<img src="https://github.com/chenhongchen/test_photos_lib/raw/master/gif/photo_browser_0.gif" width="360" height="640" alt="demo"/>

## Use it

```yaml
dependencies:
  photo_browser: 2.0.6
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
      PhotoBrowser photoBrowser = PhotoBrowser(
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
      );

      // 可以直接push
      // photoBrowser.push(context);

      // 需要的话，也可包裹在一个Widget里，这里用HCHud（一个Toast插件）包裹
      photoBrowser
          .push(context, page: HCHud(child: photoBrowser))
          .then((value) {
        print('PhotoBrowser poped');
      });
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
ImageInfo? imageInfo;
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
if (byteData != null) {
  Uint8List uint8list = byteData.buffer.asUint8List();
```

```dart
onTap: () {
  // 通过控制器，刷新PhotoBrowser
  _browerController.setState(() {});
},
```