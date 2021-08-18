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
  List<_PhoteModel> _photos = <_PhoteModel>[
    _PhoteModel(
      big:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/big_1.jpg',
      thum:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/thum_1.jpg',
    ),
    _PhoteModel(
      big:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/big_2.jpg',
      thum:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/thum_2.jpg',
    ),
    _PhoteModel(
      big:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/big_3.jpg',
      thum:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/thum_3.jpg',
    ),
    _PhoteModel(
      big:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/big_4.jpg',
      thum:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/thum_4.jpg',
    ),
    _PhoteModel(
      big:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/big_5.jpg',
      thum:
          'https://gitee.com/hongchenchen/test_photos_lib/raw/3eb1473cc183f3ff270f00450d6d54b737a0581a/thum_5.jpg',
    ),
    _PhoteModel(
        big:
            'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/big_6.jpg',
        thum:
            'https://gitee.com/hongchenchen/test_photos_lib/raw/111756917769fad2017788933725aa396091b2f2/thum_6.jpg'),
    _PhoteModel(
        big:
            'https://gitee.com/hongchenchen/test_photos_lib/raw/fc5d8c7218dddb72d624e8c9c3ea7ea0990754a3/big_7.jpg',
        thum:
            'https://gitee.com/hongchenchen/test_photos_lib/raw/fc5d8c7218dddb72d624e8c9c3ea7ea0990754a3/big_7.jpg'),
  ];

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
                scrollDirection: Axis.vertical,
                itemCount: _photos.length,
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
        PhotoBrowser(
          itemCount: _photos.length,
          initIndex: cellIndex,
          heroTagBuilder: (int index) {
            return _photos[index].big;
          },
          imageUrlBuilder: (int index) {
            return _photos[index].big;
          },
          thumImageUrlBuilder: (int index) {
            return _photos[index].thum;
          },
          onPageChanged: (int index) {},
        ).show(context);
      },
      child: Hero(
        tag: _photos[cellIndex].big,
        child: Container(
          width: 120,
          height: 120,
          child: Image.network(
            _photos[cellIndex].thum,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _PhoteModel {
  final String big;
  final String thum;

  _PhoteModel({@required this.big, this.thum});
}
