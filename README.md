# photo_browser

[![pub package](https://img.shields.io/pub/v/photo_browser.svg)](https://pub.dartlang.org/packages/photo_browser)
[![GitHub stars](https://img.shields.io/github/stars/chenhongchen/photo_browser.svg?style=social&label=Stars)](https://github.com/chenhongchen/photo_browser)

PhotoBrowser is a zoomable picture and custom view browsing plugin that supports thumbnails and provides picture data that you can use to download to your local album.

## Demo

<img src="https://github.com/chenhongchen/test_photos_lib/raw/master/gif/photo_browser_3.gif" width="270" height="480" alt="demo"/>

## Use it

### Depend on it

```yaml
dependencies:
  photo_browser: 3.0.3
```

### Import it

```dart
import 'package:photo_browser/photo_browser.dart';
```

### Creation and display of PhotoBrowser instance

```dart
Widget _buildCell(BuildContext context, int cellIndex) {
  return GestureDetector(
    onTap: () {
      PhotoBrowser photoBrowser = PhotoBrowser(
        itemCount: _bigPhotos.length,
        initIndex: cellIndex,
        controller: _browserController,
        allowTapToPop: true,
        allowSwipeDownToPop: true,
        // If allowPullDownToPop is true, the allowTapToPop setting is invalid.
        // 如果allowPullDownToPop为true，则allowTapToPop设置无效
        allowPullDownToPop: true,
        heroTagBuilder: (int index) {
          return _heroTags[index];
        },
        // Large images setting.
        // 大图设置
        imageUrlBuilder: (int index) {
          return _bigPhotos[index];
        },
        // Thumbnails setting.
        // 缩略图设置
        thumbImageUrlBuilder: (int index) {
          return _thumbPhotos[index];
        },
        positions: (BuildContext context) =>
            <Positioned>[_buildCloseBtn(context)],
        positionBuilders: <PositionBuilder>[
          _buildSaveImageBtn,
          _buildGuide,
        ],
        loadFailedChild: _failedChild(),
      );

      // You can push directly.
      // 可以直接push
      // photoBrowser.push(context);
      photoBrowser
          .push(context, page: HCHud(child: photoBrowser))
          .then((value) {
        print('PhotoBrowser closed');
      });
    },
    child: Stack(
      children: [
        Positioned.fill(
            child: Container(color: Colors.grey.withOpacity(0.6))),
        Positioned.fill(
          child: Hero(
              tag: _heroTags[cellIndex],
              child: _buildImage(cellIndex),
              placeholderBuilder:
                  (BuildContext context, Size heroSize, Widget child) =>
                      child),
        ),
      ],
    ),
  );
}
```

### Use of PhotoBrowserController

```dart
onTap: () {
  // Pop through controller
  // 通过控制器pop退出，效果和单击退出效果一样
  _browserController.pop();
},
```

```dart
onTap: () async {
  // Obtain image data through the controller
  // 通过控制器获取图片数据
  ImageInfo? imageInfo;
  if (_browserController.imageInfo[curIndex] != null) {
    imageInfo = _browserController.imageInfo[curIndex];
  } else if (_browserController.thumbImageInfo[curIndex] != null) {
    imageInfo = _browserController.thumbImageInfo[curIndex];
  }
  if (imageInfo == null) {
    return;
  }

  // Save image to album
  // 将图片保存到相册
  var byteData =
    await imageInfo.image.toByteData(format: ImageByteFormat.png);
  if (byteData != null) {
    Uint8List uint8list = byteData.buffer.asUint8List();
    var result = await ImageGallerySaver.saveImage(
    Uint8List.fromList(uint8list));
  }
}
```

```dart
onTap: () {
  // Refresh the photoBrowser through the controller
  // 通过控制器，刷新PhotoBrowser
  _browserController.setState(() {});
},
```