import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_browser/photo_browser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // https://gitee.com/hongchenchen/test_photos_lib/raw/5b67dc144b109336ce0fe6492bd7de1651973cac/pic/big_1.jpg
  String domain = 'http://gitee.com/hongchenchen/test_photos_lib/raw/';
  String path = '5b67dc144b109336ce0fe6492bd7de1651973cac';
  List<String> _photos = <String>[];
  PhotoBrowerController _browerController = PhotoBrowerController();
  bool _showTip = true;

  @override
  void initState() {
    for (int i = 1; i <= 6; i++) {
      String bigPhoto = domain + path + '/pic/big_$i.jpg';
      _photos.add(bigPhoto);
    }
    super.initState();
  }

  @override
  void dispose() {
    _browerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Photo browser example'),
          ),
          body: LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              return Container(
                margin: EdgeInsets.all(5),
                child: GridView.builder(
                  itemCount: _photos.length,
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
          )),
    );
  }

  Widget _buildCell(BuildContext context, int cellIndex) {
    return GestureDetector(
      onTap: () {
        // 弹出图片浏览器(单击或下划手势可关闭)
        PhotoBrowser(
          itemCount: _photos.length,
          initIndex: cellIndex, // 设置初始显示页面索引
          controller: _browerController,
          allowTapToPop: true, // 允许单击关闭
          allowSwipeDownToPop: true, // 允许向下轻扫关闭
          heroType: HeroType.fade, // 飞行动画类型设置
          heroTagBuilder: (int index) {
            return _photos[index];
          }, // 飞行动画tag设置，为null则弹出动画为一般的push动画
          imageUrlBuilder: (int index) {
            return _photos[index];
          }, // 大图设置，不能为空，如果想本地缓存图片可换imageProviderBuilder属性设置，然后传入带缓存功能的imageProvider
          thumImageUrlBuilder: (int index) {
            return _photos[index].replaceAll('big', 'thum');
          }, // 缩略图设置，可以为空，如果想本地缓存图片可换thumImageProviderBuilder属性设置，然后传入带缓存功能的imageProvider
          positionsBuilder: _positionsBuilder, // 可在图片浏览器上面自定义Widget，如关闭按钮
          onPageChanged: (int index) {},
        ).push(
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

  List<Positioned> _positionsBuilder(
      BuildContext context, int curIndex, int totalNum) {
    return <Positioned>[
      _buildCloseBtn(context, curIndex, totalNum),
      _buildSaveImageBtn(context, curIndex, totalNum),
      _buildGuide(context, curIndex, totalNum),
    ];
  }

  Positioned _buildCloseBtn(BuildContext context, int curIndex, int totalNum) {
    return Positioned(
      right: 15,
      top: MediaQuery.of(context).padding.top,
      child: GestureDetector(
        onTap: () {
          _browerController.pop();
        },
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          height: 44,
          child: Text(
            '关闭',
            textAlign: TextAlign.right,
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
    );
  }

  Positioned _buildSaveImageBtn(
      BuildContext context, int curIndex, int totalNum) {
    return Positioned(
      left: 15,
      bottom: 15,
      child: GestureDetector(
        onTap: () async {
          var status = await Permission.photos.request();
          if (status.isDenied) {
            print('暂无相册权限');
            showDialog(
                context: context,
                builder: (context) {
                  return GestureDetector(
                    child: Container(
                      width: 280,
                      height: 280,
                      color: Colors.white,
                      child: GestureDetector(
                        onTap: () {
                          openAppSettings();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                });
            return;
          }

          ImageInfo imageInfo;
          if (_browerController.imageInfos[curIndex] != null) {
            imageInfo = _browerController.imageInfos[curIndex];
          } else if (_browerController.thumImageInfos[curIndex] != null) {
            imageInfo = _browerController.thumImageInfos[curIndex];
          }
          if (imageInfo == null) {
            return;
          }
          // var response = await Dio().get(_photos[curIndex],
          //     options: Options(responseType: ResponseType.bytes));
          // final result = await ImageGallerySaver.saveImage(
          //     Uint8List.fromList(response.data),
          //     quality: 60,
          //     name: "hello");

          var byteData =
              await imageInfo.image.toByteData(format: ImageByteFormat.png);
          Uint8List uint8list = byteData.buffer.asUint8List();
          var result;
          try {
            result = await ImageGallerySaver.saveImage(
                Uint8List.fromList(uint8list));
          } catch (e) {
            print('result error = $e');
          }
          print(result);
          if (result != null) {
            Fluttertoast.showToast(msg: '保存成功', gravity: ToastGravity.CENTER);
          } else {
            Fluttertoast.showToast(msg: '保存失败', gravity: ToastGravity.CENTER);
          }
        },
        child: Text(
          '保存图片',
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
    );
  }

  Positioned _buildGuide(BuildContext context, int curIndex, int totalNum) {
    return _showTip
        ? Positioned(
            left: 0,
            bottom: 0,
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                _showTip = false;
                _browerController.setState(() {});
                // setState(() {});
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
                alignment: Alignment.center,
                child: Text(
                  '温馨提示😊：\n单击或向下轻扫关闭图片浏览器',
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
}
