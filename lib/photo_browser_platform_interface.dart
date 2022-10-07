import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'photo_browser_method_channel.dart';

abstract class PhotoBrowserPlatform extends PlatformInterface {
  /// Constructs a PhotoBrowserPlatform.
  PhotoBrowserPlatform() : super(token: _token);

  static final Object _token = Object();

  static PhotoBrowserPlatform _instance = MethodChannelPhotoBrowser();

  /// The default instance of [PhotoBrowserPlatform] to use.
  ///
  /// Defaults to [MethodChannelPhotoBrowser].
  static PhotoBrowserPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PhotoBrowserPlatform] when
  /// they register themselves.
  static set instance(PhotoBrowserPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
