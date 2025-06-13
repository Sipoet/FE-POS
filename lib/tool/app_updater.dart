import 'dart:io';
import 'dart:ui';

import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:open_file/open_file.dart';
import 'package:yaml/yaml.dart';

mixin AppUpdater<T extends StatefulWidget> on State<T>
    implements DefaultResponse<T> {
  bool _isDownloading = false;
  late String latestVersion;
  late String localVersion;
  String _message = '';
  void checkUpdate(Server server, {bool isManual = false}) async {
    if (kIsWeb) {
      return;
    }
    TargetPlatform platform = defaultTargetPlatform;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    localVersion = packageInfo.version;
    server.dio
        .get(
      'https://raw.githubusercontent.com/Sipoet/FE-POS/main/pubspec.yaml',
    )
        .then((response) {
      if ([200, 302].contains(response.statusCode)) {
        var doc = loadYaml(response.data);
        latestVersion = doc['version'];
        if (isOlderVersion()) {
          _showConfirmDialog(server, platform);
        } else if (isManual) {
          toastification.show(
            title: Text(
              'App already up to date',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            autoCloseDuration: Duration(seconds: 3),
            type: ToastificationType.info,
          );
        }
      }
    }, onError: (error) => defaultErrorResponse(error: error));
  }

  bool isOlderVersion() {
    final localVersions =
        localVersion.split('.').map<int>((e) => int.parse(e)).toList();
    final latestVersions =
        latestVersion.split('.').map<int>((e) => int.parse(e)).toList();
    for (final (int index, int ver) in latestVersions.indexed) {
      if (ver == localVersions[index]) {
        continue;
      }
      return ver > localVersions[index];
    }
    return false;
  }

  void _showConfirmDialog(Server server, TargetPlatform platform) {
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
                Text(
                    'Versi terbaru($latestVersion) aplikasi tersedia. apakah mau update ke terbaru?'),
                Text('versi saat ini: $localVersion'),
                const SizedBox(
                  height: 50,
                ),
                Visibility(
                  visible: _isDownloading,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    backgroundColor: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(_message),
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
                    _isDownloading = true;
                  });
                  Future.delayed(Duration.zero, () {
                    downloadApp(server, platform, setStateDialog);
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

  void downloadApp(Server server, TargetPlatform platform,
      void Function(void Function()) setStateDialog) {
    const fileSaver = FileSaver();
    final path = _downloadPath[platform];
    final extFile = path.split('.').last;
    DartPluginRegistrant.ensureInitialized();
    final navigator = Navigator.of(context);
    fileSaver.downloadPath('allegra-pos', extFile).then((String? filePath) {
      if (filePath != null) {
        setStateDialog(
          () {
            _message = 'Downloading.';
          },
        );
        server.dio.download(path, filePath,
            onReceiveProgress: (actualBytes, int totalBytes) {
          final progress = (actualBytes / totalBytes * 100).floor().toString();
          setStateDialog(() {
            _message = 'Downloading. $progress%';
          });
        }).then((value) async {
          setStateDialog(
            () {
              _isDownloading = false;
              _message = 'Download Complete.';
            },
          );
          if (platform == TargetPlatform.android ||
              platform == TargetPlatform.iOS) {
            final type = platform == TargetPlatform.android
                ? 'application/vnd.android.package-archive'
                : null;
            OpenFile.open(filePath, type: type).then((openFileResponse) {
              if (openFileResponse.type != ResultType.done) {
                return;
              } else {
                navigator.pop();
              }
            }, onError: (error) => defaultErrorResponse(error: error));
          } else if (platform == TargetPlatform.windows) {
            await installApp(filePath);
          } else {
            Flash().showBanner(
                messageType: ToastificationType.success,
                title: 'Sukses download APP',
                description: 'file installer terinstall di $filePath');
          }
        }, onError: (error) {
          setStateDialog(() {
            _message = 'gagal download installer';
            _isDownloading = false;
          });
          defaultErrorResponse(error: error);
        });
      }
    }, onError: (error) {
      _message = 'gagal cari lokasi download';
      debugPrint(error.toString());
      _isDownloading = false;
    });
  }

  Future<int?> installApk(filePath) async {
    const platformChannel = MethodChannel('android_package_installer');
    final result =
        await platformChannel.invokeMethod<int>('installApk', filePath);
    return result;
  }

  Future installApp(String filePath) {
    final navigator = Navigator.of(context);
    return Process.run(filePath, []).then((ProcessResult results) {
      navigator.pop();
    });
  }

  void openAboutDialog(String version) {
    showAboutDialog(
      context: context,
      applicationVersion: version,
      applicationName: 'Allegra Pos',
      applicationIcon: Image.asset(
        'assets/logo-allegra.jpg',
        width: 45,
        height: 45,
      ),
      applicationLegalese: '© ${DateTime.now().year} Allegra',
    );
  }
}
