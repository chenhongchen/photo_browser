import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'photo_browser_platform_interface.dart';

/// An implementation of [PhotoBrowserPlatform] that uses method channels.
class MethodChannelPhotoBrowser extends PhotoBrowserPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('photo_browser');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
