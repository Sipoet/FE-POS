import 'dart:io';

import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:open_file/open_file.dart';
import 'package:yaml/yaml.dart';

mixin AppUpdater<T extends StatefulWidget> on State<T> {
  bool _isDownloading = false;

  void checkUpdate(Server server) async {
    if (kIsWeb) {
      return;
    }
    TargetPlatform platform = defaultTargetPlatform;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    // final version = '0.1.4';
    server.dio
        .get(
      'https://raw.githubusercontent.com/Sipoet/FE-POS/main/pubspec.yaml',
    )
        .then((response) {
      if ([200, 302].contains(response.statusCode)) {
        var doc = loadYaml(response.data);
        final latestVersion = doc['version'];
        if (isOlderVersion(version, latestVersion)) {
          _showConfirmDialog(
            onSubmit: () => downloadApp(server, platform),
          );
        }
      }
    },
            onError: (error) =>
                server.defaultErrorResponse(context: context, error: error));
  }

  bool isOlderVersion(String localVersion, String remoteVersion) {
    final localVersions =
        localVersion.split('.').map<int>((e) => int.parse(e)).toList();
    final remoteVersions =
        remoteVersion.split('.').map<int>((e) => int.parse(e)).toList();
    for (final (int index, int ver) in remoteVersions.indexed) {
      if (ver != localVersions[index]) {
        return ver > localVersions[index];
      }
    }
    return true;
  }

  void _showConfirmDialog({required Function onSubmit}) {
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Text("Versi Terbaru"),
            content: Column(
              children: [
                const Text(
                    'Versi terbaru aplikasi tersedia. apakah mau update ke terbaru?'),
                Visibility(
                  visible: _isDownloading,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    backgroundColor: colorScheme.onPrimaryContainer,
                  ),
                )
              ],
            ),
            actions: [
              ElevatedButton(
                child: const Text("Kembali"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text("update sekarang"),
                onPressed: () {
                  setStateDialog(() {
                    onSubmit();
                  });
                },
              ),
            ],
          );
        });
      },
    );
  }

  final Map _downloadPath = {
    TargetPlatform.android:
        "https://raw.githubusercontent.com/Sipoet/FE-POS/main/src/android/Output/allegra-pos.apk",
    TargetPlatform.windows:
        "https://raw.githubusercontent.com/Sipoet/FE-POS/main/src/windows/Output/allegra-pos.exe"
  };

  void downloadApp(Server server, TargetPlatform platform) {
    _isDownloading = true;
    const fileSaver = FileSaver();
    final path = _downloadPath[platform];
    final extFile = path.split('.').last;
    fileSaver.downloadPath('allegra-pos', extFile).then((String? filePath) {
      if (filePath != null) {
        server.dio.download(path, filePath).then((value) async {
          if (platform == TargetPlatform.iOS ||
              platform == TargetPlatform.android) {
            OpenFile.open(filePath)
                .then((value) => Navigator.of(context).pop());
          } else if (platform == TargetPlatform.windows) {
            await installApp(filePath);
          } else {
            Flash(context).showBanner(
                messageType: MessageType.success,
                title: 'Sukses download APP',
                description: 'file installer terinstall di $filePath');
          }
        });
      }
    }).whenComplete(() {
      _isDownloading = false;
    });
  }

  Future installApp(String filePath) {
    return Process.run(filePath, []).then((ProcessResult results) {
      Navigator.of(context).pop();
    });
  }
}
