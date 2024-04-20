import 'dart:io';

import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:open_file/open_file.dart';

mixin AppUpdater<T extends StatefulWidget> on State<T> {
  bool _isDownloading = false;

  void checkUpdate(Server server) async {
    if (kIsWeb) {
      return;
    }
    String platform = defaultTargetPlatform.toString().split('.').last;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    server.get('check_update/$platform',
        queryParam: {'client_version': version}).then((response) {
      final filename = response.data['data']?['filename'];
      if (response.statusCode == 200 && filename != null) {
        showConfirmDialog(
            onSubmit: () => downloadApp(server, platform, filename),
            message:
                'Versi terbaru aplikasi tersedia. apakah mau update ke terbaru?');
      }
    },
        onError: (error) =>
            server.defaultErrorResponse(context: context, error: error));
  }

  void showConfirmDialog(
      {required Function onSubmit, String message = 'Apakah Anda Yakin'}) {
    AlertDialog alert = AlertDialog(
      title: const Text("Versi Terbaru"),
      content: Column(
        children: [
          Text(message),
          Visibility(
              visible: _isDownloading, child: const Text('downloading..'))
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
            onSubmit();
          },
        ),
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void downloadApp(Server server, String platform, String filename) async {
    const fileSaver = FileSaver();
    final extFile = filename.split('.').last;
    fileSaver.downloadPath(filename, extFile).then((String? filePath) {
      if (filePath != null) {
        setState(() {
          _isDownloading = true;
        });
        server
            .download('download_app/$platform', 'file', filePath)
            .then((value) {
          setState(() {
            _isDownloading = false;
          });
          if (platform == 'ios' || platform == 'android') {
            OpenFile.open(filePath);
          } else if (platform == 'windows') {
            installApp(filePath);
          } else {
            Flash(context).showBanner(
                messageType: MessageType.success,
                title: 'Sukses download APP',
                description: 'file installer terinstall di $filePath');
          }

          Navigator.of(context).pop();
        });
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  void installApp(String filePath) {
    Process.run(filePath, []).then((ProcessResult results) {});
  }
}
