# photo_browser

PhotoBrowser is a zoomable picture browsing plugin that supports thumbnails and provides picture data that you can use to download to your local album.

## Demo

<img src="https://github.com/chenhongchen/test_photos_lib/raw/master/gif/photo_browser_0.gif" width="360" height="640" alt="demo"/>

Pull down to pop

<img src="https://github.com/chenhongchen/test_photos_lib/raw/master/gif/photo_browser_1.gif" width="360" height="640" alt="demo"/>

## Use it

```yaml
dependencies:
  photo_browser: 2.0.7
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
        allowPullDownToPop: true,
        // If heroTagBuilder is null, the pop animation is a general push animation.
        heroTagBuilder: (int index) {
          return _heroTags[index];
        },
        // Images setting.
        // If you want the displayed image to be cached to disk at the same time,
        // you can set the imageProviderBuilder property instead imageUrlBuilder,
        // then set it with imageProvider with disk caching function.
        imageUrlBuilder: (int index) {
          return _bigPhotos[index];
        },
        // Thumbnails setting.
        // If you want the displayed thumbnail to be cached to disk at the same time,
        // you can set the thumImageProviderBuilder property instead thumImageUrlBuilder,
        // then set it with imageProvider with disk caching function.
        thumImageUrlBuilder: (int index) {
          return _thumPhotos[index];
        },
        // Through the positionsBuilder property，
        // you can create widgets on the photo browser,
        // such as close button and save button.
        positionsBuilder: _positionsBuilder,
        loadFailedChild: _failedChild(),
        onPageChanged: (int index) {
          _curIndex = index;
        },
      );

      // You can push directly.
      // photoBrowser.push(context);

      // If necessary, it can also be wrapped in a widget
      // Here it is wrapped with HCHud (a toast plugin)
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
                child: Image.network(
                  _thumPhotos[cellIndex],
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                  child: Hero(
                    tag: _heroTags[cellIndex],
                    child: Image.network(
                      _thumPhotos[cellIndex],
                      fit: BoxFit.cover,
                    ),
                  )),
            ],
          )
        : Hero(
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
  // Pop through controller
  _browerController.pop();
},
```

```dart
// Through the controller,
// the picture data is obtained and converted into uint8list,
// which can be used to save to the album
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
  _browerController.setState(() {});
},
```