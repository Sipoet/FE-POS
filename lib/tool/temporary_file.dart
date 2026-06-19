import 'dart:io';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract class TempFile {
  static Future<File> create(String ext, {Uint8List? bytes}) async {
    final dir = await getApplicationCacheDirectory();
    final uuidGenerator = Uuid();
    String uuid = uuidGenerator.v7();
    File file = File(p.join(dir.path, '$uuid.$ext'));
    if (bytes == null) {
      return file;
    }
    return file.writeAsBytes(bytes);
  }

  static clearTempFile() {}
}
