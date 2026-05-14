import 'dart:typed_data';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileSaver with PlatformChecker {
  const FileSaver();

  Future<String?> pickPath({
    required String filename,
    required String extFile,
    Uint8List? bytes,
  }) async {
    final dir = await getApplicationCacheDirectory();
    return FilePicker.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: filename,
      initialDirectory: dir.path,
      type: FileType.custom,
      allowedExtensions: [extFile],
      bytes: bytes,
    );
  }

  String? mimeTypeOf(String ext) {
    if (ext == 'apk') {
      return 'application/vnd.android.package-archive';
    }
    return null;
  }

  void download(
    String filename,
    List<int> bytes,
    String extFile, {
    void Function(String path)? onSuccess,
    void Function(String path)? onFailed,
  }) async {
    String? outputFile = await pickPath(
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
    String? path,
    String? url,
    required Server server,
    String? filename,
    required ContentType acceptHeader,
    bool chooseFile = true,
    void Function(int, int)? onReceiveProgress,
  }) async {
    Uint8List? bytes = await server.download(
      path: path,
      url: url,
      acceptHeader: acceptHeader,
      onSuccess: (response) {
        String headerFilename =
            response.headers.value('content-disposition') ?? '';
        if (headerFilename.isEmpty) {
          return;
        }
        headerFilename = headerFilename.substring(
          headerFilename.indexOf('filename="') + 10,
          headerFilename.indexOf('${acceptHeader.extName}";') + 4,
        );
        filename ??= headerFilename;
      },
      onReceiveProgress: onReceiveProgress,
    );
    if (bytes == null) {
      return null;
    }
    if (chooseFile) {
      String? outputFile = await pickPath(
        filename: filename ?? 'file.${acceptHeader.extName}',
        extFile: acceptHeader.extName ?? '.txt',
        bytes: bytes,
      );
      if (outputFile == null) {
        return null;
      }
      return File(outputFile);
    }
    final dir = await getApplicationCacheDirectory();
    File file = File(p.join(dir.path, filename));
    file.writeAsBytesSync(bytes, flush: true);
    return file;
  }
}
