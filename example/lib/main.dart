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
  static String get smallImageParam =>
      '?x-oss-process=image/resize,w_300/sharpen,100/quality,Q_100';
  static String get middleImageParam =>
      '?x-oss-process=image/resize,w_600/sharpen,100/quality,Q_100';
  static String get largeImageParam =>
      '?x-oss-process=image/resize,w_1024/sharpen,100/quality,Q_100';

  String domain = 'https://qzasset.jinriaozhou.com';

  List photos = [
    '/quanzi/2021/20210730/31cd8d37b317d055985e3ffa8e1bb77e_1606x1204.jpeg',
    '/quanzi/2021/20210730/606a114741bf46bbe2f0365eb6baea2b_1200x1600.jpeg',
    '/quanzi/2021/20210730/ab7dfe598f5a60165c229d6d3155cf00_1200x1600.jpeg',
    '/quanzi/2021/20210730/f0e1d5c328b59ba8c2e9ea17a1b31cc6_1200x1600.jpeg',
    '/quanzi/2021/20210730/9d41e346a0d324bc6ea4e99fb31fddc8_1200x1600.jpeg',
    '/quanzi/2021/20210730/c725f29809dcac2ba046c9e0156e0654_1606x1204.jpeg'
  ];

  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              return ListView.builder(
                itemCount: photos.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildCell(context, index);
                },
              );
            },
          )),
    );
  }

  Widget _buildCell(BuildContext context, int cellIndex) {
    return GestureDetector(
      onTap: () {
        _pageIndex = cellIndex;
        PhotoBrowser(
          itemCount: photos.length,
          initIndex: cellIndex,
          heroTagBuilder: (int index) {
            return photos[index];
          },
          imageUrlBuilder: (int index) {
            return domain + photos[index];
          },
          thumImageUrlBuilder: (int index) {
            return domain + photos[index] + smallImageParam;
          },
          onPageChanged: (int index) {
            _pageIndex = index;
          },
        ).show(context);
      },
      child: Hero(
        tag: photos[cellIndex],
        child: Container(
          width: 120,
          height: 120,
          child: Image.network(
            domain + photos[cellIndex] + smallImageParam,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
