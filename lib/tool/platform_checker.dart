import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

mixin PlatformChecker {
  bool isWeb() {
    return kIsWeb;
  }

  bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }

  bool isDesktop() {
    return Platform.isLinux ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isFuchsia;
  }

  Future<String> appVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
