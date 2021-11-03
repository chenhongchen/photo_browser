import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_browser/photo_browser.dart';

class EasyDemoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EasyDemoPage();
  }
}

class _EasyDemoPage extends State<EasyDemoPage> {
  String domain =
      'https://gitee.com/hongchenchen/test_photos_lib/raw/master/pic/';
  List<String> _bigPhotos = <String>[];
  List<String> _thumPhotos = <String>[];
  List<String> _heroTags = <String>[];

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '简单例子/Easy demo',
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
        PhotoBrowser(
          itemCount: _bigPhotos.length,
          initIndex: cellIndex,
          heroTagBuilder: (int index) {
            return _heroTags[index];
          },
          imageUrlBuilder: (int index) {
            return _bigPhotos[index];
          },
          thumImageUrlBuilder: (int index) {
            return _thumPhotos[index];
          },
        ).push(context);
      },
      child: Hero(
        tag: _heroTags[cellIndex],
        child: _buildImage(cellIndex),
      ),
    );
  }

  Widget _buildImage(int index) {
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
}
