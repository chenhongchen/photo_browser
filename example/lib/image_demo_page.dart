import 'dart:typed_data';
import 'dart:ui';

import 'package:flt_hc_hud/flt_hc_hud.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_browser/photo_browser.dart';

class ImageDemoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImageDemoPage();
  }
}

class _ImageDemoPage extends State<ImageDemoPage> {
  String domain =
      'https://gitee.com/hongchenchen/test_photos_lib/raw/master/pic/';
  List<String> _bigPhotos = <String>[];
  List<String> _thumbPhotos = <String>[];
  List<String> _heroTags = <String>[];
  PhotoBrowserController _browserController = PhotoBrowserController();
  bool _showTip = true;

  @override
  void initState() {
    for (int i = 1; i <= 6; i++) {
      String bigPhoto = domain + 'big_$i.jpg';
      _bigPhotos.add(bigPhoto);
      String thumbPhoto = domain + 'thum_$i.jpg';
      _thumbPhotos.add(thumbPhoto);
      _heroTags.add(thumbPhoto);
    }
    super.initState();
  }

  @override
  void dispose() {
    _browserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '仅图片\nOnly image',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          return Container(
            margin: EdgeInsets.all(5),
            child: GridView.builder(
              itemCount: _thumbPhotos.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 1),
              itemBuilder: (BuildContext context, int index) {
                return _buildCell(context, index);
              },
            ),
          );
        },
      ),
    );
  }

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

  Widget _buildImage(int index) {
    return Image.network(
      _thumbPhotos[index],
      fit: BoxFit.cover,
    );
  }

  Positioned _buildCloseBtn(BuildContext context) {
    return Positioned(
      right: 15,
      top: MediaQuery.of(context).padding.top + 10,
      child: GestureDetector(
        onTap: () {
          // Pop through controller
          // 通过控制器pop退出
          _browserController.pop();
        },
        child: Icon(
          Icons.close,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Positioned _buildSaveImageBtn(
      BuildContext context, int curIndex, int totalNum) {
    return Positioned(
      left: 20,
      bottom: 20,
      child: GestureDetector(
        onTap: () async {
          var status = await Permission.photos.request();
          if (status.isDenied) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('提示'),
                  content: Text('需要授权使用相册才能保存，去授权？'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text('去授权'),
                      onPressed: () {
                        openAppSettings();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
            return;
          }

          // Obtain image data through the controller
          // 通过控制器获取图片数据
          ImageInfo? imageInfo;
          if (_browserController.imageInfo[curIndex] != null) {
            imageInfo = _browserController.imageInfo[curIndex];
          } else if (_browserController.thumbImageInfo[curIndex] != null) {
            imageInfo = _browserController.thumbImageInfo[curIndex];
          }
          if (imageInfo == null) {
            HCHud.of(context)?.showErrorAndDismiss(text: '没有发现图片');
            return;
          }

          HCHud.of(context)?.showLoading(text: '正在保存...');

          // Save image to album
          // 将图片保存到相册
          var byteData =
              await imageInfo.image.toByteData(format: ImageByteFormat.png);
          if (byteData != null) {
            Uint8List uint8list = byteData.buffer.asUint8List();
            var result = await ImageGallerySaver.saveImage(
                Uint8List.fromList(uint8list));
            if (result != null) {
              HCHud.of(context)?.showSuccessAndDismiss(text: '保存成功');
            } else {
              HCHud.of(context)?.showErrorAndDismiss(text: '保存失败');
            }
          }
        },
        child: Icon(
          Icons.save,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Positioned _buildGuide(BuildContext context, int curIndex, int totalNum) {
    return _showTip
        ? Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _showTip = false;
                // Refresh the photoBrowser through the controller
                // 通过控制器，刷新PhotoBrowser
                _browserController.setState(() {});
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
                alignment: Alignment.center,
                child: Text(
                  '温馨提示😊：\n可单击或下拉退出浏览',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(230),
                    decoration: TextDecoration.none,
                    shadows: <Shadow>[
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
              ),
            ),
          )
        : Positioned(
            child: Container(),
          );
  }

  Widget _failedChild() {
    return Center(
      child: Material(
        child: Container(
          child: Text(
            '加载图片失败',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
