import 'dart:typed_data';
import 'dart:ui';

import 'package:flt_hc_hud/flt_hc_hud.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_browser/page/custom_page.dart';
import 'package:photo_browser/photo_browser.dart';
import 'package:photo_browser_example/video_view.dart';

class ImageCustomDemoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImageCustomDemoPageState();
  }
}

class _ImageCustomDemoPageState extends State<ImageCustomDemoPage> {
  String domain =
      'https://gitee.com/hongchenchen/test_photos_lib/raw/master/pic/';
  List<String> _bigPhotos = <String>[];
  List<String> _thumPhotos = <String>[];
  List<String> _heroTags = <String>[];
  PhotoBrowerController _browerController = PhotoBrowerController();
  int? _initIndex;
  int? _curIndex;

  @override
  void initState() {
    for (int i = 0; i < 8; i++) {
      String bigPhoto = domain + 'big_${i + 1}.jpg';
      String thumPhoto = domain + 'thum_${i + 1}.jpg';
      if (i == 6 || i == 7) {
        bigPhoto = 'widget_$i';
        thumPhoto = bigPhoto;
      }
      _bigPhotos.add(bigPhoto);
      _thumPhotos.add(thumPhoto);
      _heroTags.add(thumPhoto);
    }
    super.initState();
  }

  @override
  void dispose() {
    _browerController.dispose();
    super.dispose();
  }

  bool _isCustomType(int index) {
    return _bigPhotos[index] == 'widget_$index';
  }

  List<Shadow> _shadows() {
    return <Shadow>[
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
            margin: EdgeInsets.all(5),
            child: GridView.builder(
              itemCount: _thumPhotos.length,
              physics: NeverScrollableScrollPhysics(),
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

  Widget _buildImage(int index) {
    if (_isCustomType(index)) {
      if (index == 6) {
        return _buildCustomImage(
          font: 10,
          fill: true,
        );
      } else {
        return _buildCustomImage(font: 12, fill: true, text: '视频(video)');
      }
      // return Container(color: Colors.teal);
    }
    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.grey.withOpacity(0.6))),
        Positioned.fill(
            child: Image.network(
          _thumPhotos[index],
          fit: BoxFit.cover,
        )),
      ],
    );
  }

  _buildCustomImage(
      {double font = 16,
      bool fill = false,
      String text = '自定义页(Custom page)'}) {
    return Material(
      child: Stack(
        children: [
          Positioned.fill(
              child: Container(color: Colors.grey.withOpacity(0.6))),
          fill
              ? Positioned.fill(
                  child: Image.network(_thumPhotos[0], fit: BoxFit.cover))
              : Image.network(_thumPhotos[0], fit: BoxFit.cover),
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

  List<Positioned> _positionsBuilder(
      BuildContext context, int curIndex, int totalNum) {
    return <Positioned>[
      _buildCloseBtn(context, curIndex, totalNum),
      _buildSaveImageBtn(context, curIndex, totalNum),
    ];
  }

  Positioned _buildCloseBtn(BuildContext context, int curIndex, int totalNum) {
    return Positioned(
      right: 20,
      top: MediaQuery.of(context).padding.top + 10,
      child: GestureDetector(
        onTap: () {
          // Pop through controller
          // 通过控制器pop退出
          _browerController.pop();
        },
        child: Icon(
          Icons.close,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Positioned _buildSaveImageBtn(
      BuildContext context, int curIndex, int totalNum) {
    if (_thumPhotos[curIndex].contains('widget_')) {
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
          if (_browerController.imageInfos[curIndex] != null) {
            imageInfo = _browerController.imageInfos[curIndex];
          } else if (_browerController.thumImageInfos[curIndex] != null) {
            imageInfo = _browerController.thumImageInfos[curIndex];
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
          size: 36,
        ),
      ),
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
