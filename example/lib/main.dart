import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_browser/photo_browser.dart';
import 'package:flt_hc_hud/flt_hc_hud.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // https://gitee.com/hongchenchen/test_photos_lib/raw/master/pic/big_1.jpg
  String domain =
      'https://gitee.com/hongchenchen/test_photos_lib/raw/master/pic/';
  List<String> _bigPhotos = <String>[];
  List<String> _thumPhotos = <String>[];
  List<String> _heroTags = <String>[];
  PhotoBrowerController _browerController = PhotoBrowerController();
  bool _showTip = true;

  @override
  void initState() {
    for (int i = 1; i <= 6; i++) {
      String bigPhoto = domain + 'big_$i.jpg';
      _bigPhotos.add(bigPhoto);
      String thumPhoto = domain + 'thum_$i.jpg';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
          )),
    );
  }

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
        photoBrowser.push(context, page: HCHud(child: photoBrowser));
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

  List<Positioned> _positionsBuilder(
      BuildContext context, int curIndex, int totalNum) {
    return <Positioned>[
      _buildCloseBtn(context, curIndex, totalNum),
      _buildSaveImageBtn(context, curIndex, totalNum),
      _buildGuide(context, curIndex, totalNum),
    ];
  }

  // 关闭按钮
  Positioned _buildCloseBtn(BuildContext context, int curIndex, int totalNum) {
    return Positioned(
      right: 20,
      top: MediaQuery.of(context).padding.top,
      child: GestureDetector(
        onTap: () {
          // 通过控制器pop
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

  // 保存图片按钮
  Positioned _buildSaveImageBtn(
      BuildContext context, int curIndex, int totalNum) {
    return Positioned(
      left: 20,
      bottom: 20,
      child: GestureDetector(
        onTap: () async {
          // 使用相册授权
          var status = await Permission.photos.request();
          if (status.isDenied) {
            showDialog(
              context: context,
              barrierDismissible: false, //// user must tap button!
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

          // 通过控制器，获取图片数据
          ImageInfo? imageInfo;
          if (_browerController.imageInfos[curIndex] != null) {
            imageInfo = _browerController.imageInfos[curIndex];
          } else if (_browerController.thumImageInfos[curIndex] != null) {
            imageInfo = _browerController.thumImageInfos[curIndex];
          }
          if (imageInfo == null) {
            HCHud.of(context).showErrorAndDismiss(text: '没有发现图片');
            return;
          }

          HCHud.of(context).showLoading(text: '正在保存...');

          // 转换数据及保存为图片
          var byteData =
              await imageInfo.image.toByteData(format: ImageByteFormat.png);
          if (byteData != null) {
            Uint8List uint8list = byteData.buffer.asUint8List();
            var result = await ImageGallerySaver.saveImage(
                Uint8List.fromList(uint8list));
            if (result != null) {
              HCHud.of(context).showSuccessAndDismiss(text: '保存成功');
            } else {
              HCHud.of(context).showErrorAndDismiss(text: '保存失败');
            }
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

  // 手势引导界面
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
                // 通过控制器，刷新PhotoBrowser
                _browerController.setState(() {});
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
