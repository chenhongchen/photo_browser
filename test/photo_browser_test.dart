import 'package:flutter_test/flutter_test.dart';
import 'package:photo_browser/photo_browser_platform_interface.dart';
import 'package:photo_browser/photo_browser_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPhotoBrowserPlatform
    with MockPlatformInterfaceMixin
    implements PhotoBrowserPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PhotoBrowserPlatform initialPlatform = PhotoBrowserPlatform.instance;

  test('$MethodChannelPhotoBrowser is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPhotoBrowser>());
  });

  test('getPlatformVersion', () async {
    // PhotoBrowser photoBrowserPlugin = PhotoBrowser();
    MockPhotoBrowserPlatform fakePlatform = MockPhotoBrowserPlatform();
    PhotoBrowserPlatform.instance = fakePlatform;

    // expect(await photoBrowserPlugin.getPlatformVersion(), '42');
  });
}
