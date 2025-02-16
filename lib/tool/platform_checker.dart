import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'dart:io' show Platform;

mixin PlatformChecker {
  bool isWeb() {
    return kIsWeb;
  }

  bool isMobile() {
    if (isWeb()) {
      return [TargetPlatform.android, TargetPlatform.iOS]
          .contains(defaultTargetPlatform);
    } else {
      return Platform.isAndroid || Platform.isIOS;
    }
  }

  bool isDesktop() {
    return !isMobile();
  }

  Future<String> appVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
