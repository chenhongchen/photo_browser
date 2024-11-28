/*
 * @Author: A kingiswinter@gmail.com

import 'image_demo_page.dart';
 * @Date: 2024-11-28 16:02:49
 * @LastEditors: A kingiswinter@gmail.com
 * @LastEditTime: 2024-11-28 16:03:15
 * @FilePath: /photo_browser/example/lib/main.dart
 * 
 * Copyright (c) 2024 by A kingiswinter@gmail.com, All Rights Reserved.
 */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'image_custom_demo_page.dart';
import 'image_demo_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo browser example'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCell(
              cn: '仅图片',
              en: 'Only image',
              color: Colors.purpleAccent,
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .push(CupertinoPageRoute(builder: (BuildContext context) {
                  return const ImageDemoPage();
                }));
              }),
          _buildCell(
              cn: '图片和自定义',
              en: 'Image and custom',
              icon: Icons.widgets,
              color: Colors.teal,
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .push(CupertinoPageRoute(builder: (BuildContext context) {
                  return const ImageCustomDemoPage();
                }));
              }),
        ],
      ),
    );
  }

  Widget _buildCell(
      {String cn = '',
      String en = '',
      IconData icon = Icons.image,
      Color? color,
      VoidCallback? onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(icon, size: 44, color: color),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(cn, overflow: TextOverflow.ellipsis),
                      Text(en, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        Container(height: 0.3, color: Colors.black.withOpacity(0.1)),
      ],
    );
  }
}
