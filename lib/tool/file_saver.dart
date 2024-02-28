import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FileSaver {
  const FileSaver();

  Future webDownload(String filename, List<int> bytes) async {
    final base64 = base64Encode(bytes);
    // Create the link with the file
    final anchor =
        html.AnchorElement(href: 'data:application/octet-stream;base64,$base64')
          ..target = 'blank';
    anchor.download = filename;
    // trigger download
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  }

  Future<String?> downloadPath(String filename, String extFile) async {
    String? outputFile;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      Directory? dir = await getDownloadsDirectory();
      outputFile = "${dir?.path}/$filename";
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      Directory? dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir = await getExternalStorageDirectory();
      }
      outputFile = "${dir?.path}/$filename";
    } else if ([
      TargetPlatform.linux,
      TargetPlatform.windows,
      TargetPlatform.macOS
    ].contains(defaultTargetPlatform)) {
      outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: [extFile]);
    }
    return outputFile;
  }

  void download(String filename, List<int> bytes, String extFile,
      {void Function(String path)? onSuccess,
      void Function(String path)? onFailed}) async {
    if (kIsWeb) {
      await webDownload(filename, bytes);
      return;
    }
    String? outputFile = await downloadPath(filename, extFile);
    if (outputFile != null) {
      File file = File(outputFile);
      file.writeAsBytesSync(bytes);
      if (onSuccess != null) {
        onSuccess(file.path);
      }
    } else if (onFailed != null) {
      onFailed('failed save file');
    }
  }
}
