# photo_browser

PhotoBrowser is a zoomable picture browsing plugin that supports thumbnails and provides picture data that you can use to download to your local album.

## Demo

<img src="https://github.com/chenhongchen/test_photos_lib/raw/master/gif/photo_browser_3.gif" width="270" height="480" alt="demo"/>

## Use it

```yaml
dependencies:
  photo_browser: 2.0.11
```

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
        controller: _browerController,
        allowTapToPop: true,
        allowSwipeDownToPop: true,
        // If allowPullDownToPop is true, the allowTapToPop setting is invalid.
        // 如果allowPullDownToPop为true，则allowTapToPop设置无效
        allowPullDownToPop: true,
        heroTagBuilder: (int index) {
          return _heroTags[index];
        },
        // Set the display type of each page,
        // if the value is null, all are DisplayType.image.
        // 设置每页显示的类型，值为null则都为DisplayType.image类型
        displayTypeBuilder: (int index) {
          if (_isCustomType(index)) {
            return DisplayType.custom;
          }
          return DisplayType.image;
        },
        // Large images setting.
        // If you want the displayed image to be cached to disk at the same time,
        // you can set the imageProviderBuilder property instead imageUrlBuilder,
        // then set it with imageProvider with disk caching function.
        // 大图设置，如果希望图片显示的同时进行磁盘缓存可换imageProviderBuilder属性设置，
        // 然后传入带磁盘缓存功能的imageProvider
        imageUrlBuilder: (int index) {
          return _bigPhotos[index];
        },
        // Thumbnails setting.
        // 缩略图设置
        thumImageUrlBuilder: (int index) {
          return _thumPhotos[index];
        },
        // Called when the display type is DisplayType.custom.
        // 当显示类型为DisplayType.custom时会调用
        customChildBuilder: (int index) {
          if (index == 6) {
            return CustomChild(
              child: _buildCustomImage(),
              allowZoom: true,
            );
          } else {
            return CustomChild(
              child: VideoView(),
              allowZoom: false,
            );
          }
        },
        positionsBuilder: _positionsBuilder,
        loadFailedChild: _failedChild(),
        onPageChanged: (int index) {
          _curIndex = index;
        },
      );

      // You can push directly.
      // 可以直接push
      // photoBrowser.push(context);

      // If necessary, it can also be wrapped in a widget
      // Here it is wrapped with HCHud (a toast plugin)
      // 需要的话，也可包裹在一个Widget里，这里用HCHud（一个Toast插件）包裹
      photoBrowser
          .push(context, page: HCHud(child: photoBrowser))
          .then((value) {
        setState(() {});
        Future.delayed(Duration(milliseconds: 600), () {
          _initIndex = null;
          _curIndex = null;
          setState(() {});
        });
        print('PhotoBrowser poped');
      });

      setState(() {
        _initIndex = cellIndex;
      });
    },
    child: _initIndex == cellIndex || _curIndex == cellIndex
        ? Stack(
            children: [
              Positioned.fill(
                child: _buildImage(cellIndex),
              ),
              Positioned.fill(
                child: Hero(
                  tag: _heroTags[cellIndex],
                  child: _buildImage(cellIndex),
                ),
              ),
            ],
          )
        : Hero(
            tag: _heroTags[cellIndex],
            child: _buildImage(cellIndex),
          ),
  );
}
```

### Use of PhotoBrowerController

```dart
onTap: () {
  // Pop through controller
  // 通过控制器pop退出，效果和单击退出效果一样
  _browerController.pop();
},
```

```dart
// Through the controller,
// the picture data is obtained and converted into uint8list,
// which can be used to save to the album
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
  // Refresh the photoBrowser through the controller
  // 通过控制器，刷新PhotoBrowser
  _browerController.setState(() {});
},
```