import 'dart:typed_data';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FileSaver with PlatformChecker {
  const FileSaver();

  Future<String?> downloadPath({
    required String filename,
    required String extFile,
    Uint8List? bytes,
  }) {
    return FilePicker.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: [extFile],
      bytes: isDesktop() ? null : bytes,
    );
  }

  void download(
    String filename,
    List<int> bytes,
    String extFile, {
    void Function(String path)? onSuccess,
    void Function(String path)? onFailed,
  }) async {
    String? outputFile = await downloadPath(
      filename: filename,
      extFile: extFile,
      bytes: Uint8List.fromList(bytes),
    );
    if (outputFile != null) {
      File file = File(outputFile);
      if (isDesktop()) {
        file.writeAsBytesSync(bytes);
      }
      if (onSuccess != null) {
        onSuccess(file.path);
      }
    } else if (onFailed != null) {
      onFailed('failed save file');
    }
  }

  Future<File?> downloadRemote({
    required String urlPath,
    required Server server,
    String? filename,
    required String extFile,
    void Function(int, int)? onReceiveProgress,
  }) async {
    Uint8List? bytes = await server.download(
      urlPath: urlPath,
      type: extFile,
      onSuccess: (response) {
        String headerFilename =
            response.headers.value('content-disposition') ?? '';
        if (headerFilename.isEmpty) {
          return;
        }
        headerFilename = headerFilename.substring(
          headerFilename.indexOf('filename="') + 10,
          headerFilename.indexOf('$extFile";') + 4,
        );
        filename ??= headerFilename;
      },
      onReceiveProgress: onReceiveProgress,
    );
    if (bytes == null) {
      return null;
    }
    String? outputFile = await downloadPath(
      filename: filename!,
      extFile: extFile,
      bytes: bytes,
    );
    if (outputFile != null) {
      return File(outputFile);
    }
    return null;
  }
}
