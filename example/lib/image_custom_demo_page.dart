import 'dart:io';
import 'dart:ui';

import 'package:flt_hc_hud/flt_hc_hud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photos_browser/page/custom_page.dart';
import 'package:photos_browser/photo_browser.dart';
import 'package:saver_gallery/saver_gallery.dart';

import 'video_view.dart';

class ImageCustomDemoPage extends StatefulWidget {
  const ImageCustomDemoPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ImageCustomDemoPageState();
  }
}

class _ImageCustomDemoPageState extends State<ImageCustomDemoPage> {
  String domain =
      'https://gitee.com/hongchenchen/test_photos_lib/raw/master/pic/';
  final List<String> _bigPhotos = <String>[];
  final List<String> _thumbPhotos = <String>[];
  final List<String> _heroTags = <String>[];
  final PhotoBrowserController _browserController = PhotoBrowserController();

  @override
  void initState() {
    // video_player 不支持 macOS
    int num = (Platform.isIOS || Platform.isAndroid) ? 8 : 7;
    for (int i = 0; i < num; i++) {
      String bigPhoto = '${domain}big_${i + 1}.jpg';
      String thumbPhoto = '${domain}thum_${i + 1}.jpg';
      if (i == 6 || i == 7) {
        bigPhoto = 'widget_$i';
        thumbPhoto = bigPhoto;
      }
      _bigPhotos.add(bigPhoto);
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

  bool _isCustomType(int index) {
    return _bigPhotos[index] == 'widget_$index';
  }

  List<Shadow> _shadows() {
    return <Shadow>[
      const Shadow(
        offset: Offset(1.0, 1.0),
        blurRadius: 3.0,
        color: Colors.black,
      ),
      const Shadow(
        offset: Offset(1.0, 1.0),
        blurRadius: 8.0,
        color: Colors.black,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '图片和自定义\nImage and custom',
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
            margin: const EdgeInsets.all(5),
            child: GridView.builder(
              itemCount: _thumbPhotos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          allowTapToPopBuilder: (int index) {
            if (index == 7) {
              return false;
            }
            return true;
          },
          allowSwipeDownToPop: true,
          // If allowPullDownToPop is true, the allowSwipeDownToPop setting is invalid.
          // 如果allowPullDownToPop为true，则allowSwipeDownToPop设置无效
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
          // 大图设置
          imageUrlBuilder: (int index) {
            return _bigPhotos[index];
          },
          // Thumbnails setting.
          // 缩略图设置
          thumbImageUrlBuilder: (int index) {
            return _thumbPhotos[index];
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
                child: const VideoView(),
                allowZoom: false,
              );
            }
          },
          positions: (BuildContext context) =>
              <Positioned>[_buildCloseBtn(context)],
          positionBuilders: <PositionBuilder>[
            if (Platform.isIOS || Platform.isAndroid) _buildSaveImageBtn,
          ],
          loadFailedChild: _failedChild(),
        );

        // You can push directly.
        // 可以直接push
        // photoBrowser.push(context);
        photoBrowser
            .push(context, page: HCHud(child: photoBrowser))
            .then((value) {
          if (kDebugMode) {
            print('PhotoBrowser closed');
          }
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
    if (_isCustomType(index)) {
      if (index == 6) {
        return _buildCustomImage(font: 10);
      } else {
        return _buildCustomImage(font: 12, text: '视频(video)');
      }
    }
    return Image.network(
      _thumbPhotos[index],
      fit: BoxFit.cover,
    );
  }

  _buildCustomImage({double font = 16, String text = '自定义页(Custom page)'}) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
              child: Image.network(_thumbPhotos[0], fit: BoxFit.cover)),
          Positioned(
              left: 5,
              top: 5,
              right: 5,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: font,
                  color: Colors.white,
                  shadows: _shadows(),
                ),
              )),
        ],
      ),
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
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Positioned _buildSaveImageBtn(
      BuildContext context, int curIndex, int totalNum) {
    if (_thumbPhotos[curIndex].contains('widget_')) {
      return Positioned(child: Container());
    }
    return Positioned(
      left: 20,
      bottom: 20,
      child: GestureDetector(
        onTap: () async {
          var status = await Permission.photos.request();
          if (status.isDenied) {
            showDialog(
              // ignore: use_build_context_synchronously
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('提示'),
                  content: const Text('需要授权使用相册才能保存，去授权？'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: const Text('去授权'),
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

          if (!mounted) return;
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
            var result = await SaverGallery.saveImage(
              Uint8List.fromList(uint8list),
              fileName: 'image',
              skipIfExists: false,
            );
            if (!mounted) return;
            if (result.isSuccess) {
              HCHud.of(context)?.showSuccessAndDismiss(text: '保存成功');
            } else {
              HCHud.of(context)?.showErrorAndDismiss(text: '保存失败');
            }
          }
        },
        child: const Icon(
          Icons.save,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _failedChild() {
    return const Center(
      child: Material(
        child: Text(
          '加载图片失败',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
