import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_browser/photo_browser.dart';

void main() {
  const MethodChannel channel = MethodChannel('photo_browser');

  TestWidgetsFlutterBinding.ensureInitialized();
}
