import 'package:flutter/material.dart';
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

  @override
  void initState() {
    for (int i = 1; i <= 6; i++) {
      String bigPhoto = domain + path + '/pic/big_$i.jpg';
      _photos.add(bigPhoto);
    }
    super.initState();
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
          initIndex: cellIndex, // 设置初始显示页面
          heroTagBuilder: (int index) {
            return _photos[index];
          }, // 飞行动画tag设置，为null则弹出动画为一般的push动画
          imageUrlBuilder: (int index) {
            return _photos[index];
          }, // 大图设置，不能为空，如果想本地缓存图片可换imageProviderBuilder属性设置，然后传入带缓存功能的imageProvider
          thumImageUrlBuilder: (int index) {
            return _photos[index].replaceAll('big', 'thum');
          }, // 缩略图设置，可以为空，如果想本地缓存图片可换thumImageProviderBuilder属性设置，然后传入带缓存功能的imageProvider
          positionsBuilder: (int curIndex, int totalNum) {
            return <Positioned>[
              Positioned(
                right: 15,
                top: 35,
                child: Text(
                  '保存图片',
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
              )
            ];
          },
          onPageChanged: (int index) {},
        ).show(
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
}
