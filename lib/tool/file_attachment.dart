import 'dart:typed_data';

import 'package:fe_pos/tool/image_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fe_pos/model/server.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

abstract class FileAttachment {
  XFile? file;
  String? mimeType;
  String? filename;
  String? secureUrl;
  String? signedId;
  int? fileSize;
  int? id;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool _flagDestroyed = false;

  FileAttachment({
    this.file,
    this.mimeType,
    this.filename,
    this.secureUrl,
    this.signedId,
    this.fileSize,
    this.id,
    this.createdAt,
    this.updatedAt,
  }) {
    assert(
      !(id != null && secureUrl == null),
      'secureUrl must filled if id not null',
    );
  }

  bool get isAttached => id != null;
  bool get isDestroyed => _flagDestroyed;

  void flagDestroy() {
    _flagDestroyed = true;
  }

  void unflagDestroy() {
    _flagDestroyed = false;
  }

  Future<dynamic> dataAsync() async {
    if (id == null) {
      if (file == null) {
        return null;
      }
      return MultipartFile.fromBytes(
        await file!.readAsBytes(),
        filename: filename,
        contentType: mimeType == null ? null : .parse(mimeType!),
      );
    } else {
      return {'id': id, '_destroy': _flagDestroyed, 'type': 'file'};
    }
  }

  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'] ?? {};
    secureUrl = attributes['secure_url'];
    signedId = attributes['signed_id'];
    mimeType = attributes['content_type'];
    id = int.tryParse(json['id'] ?? '');
    createdAt = DateTime.tryParse(attributes['created_at'] ?? '');
    updatedAt = DateTime.tryParse(attributes['updated_at'] ?? '');
  }

  Widget thumbnail({double? width, double? height});

  void showPreview(BuildContext context);
}

class FileAttachmentClass<T extends FileAttachment> {
  T initModel(String type) {
    switch (type) {
      case 'image':
        return ImageModel() as T;
      case 'pdf':
        return PdfModel() as T;
      default:
        throw 'not support type $type';
    }
  }

  T fromFile(XFile file) {
    final fileExt = getFileExt(file.name);
    if (['png', 'jpg', 'webp', 'jpeg', 'bmp', 'svg'].contains(fileExt)) {
      return ImageModel(
            file: file,
            mimeType: file.mimeType ?? 'image/$fileExt',
            filename: file.name,
          )
          as T;
    } else if (fileExt == 'pdf') {
      return PdfModel(
            file: file,
            mimeType: 'application/pdf',
            filename: file.name,
          )
          as T;
    }
    throw 'not supported';
  }

  // from drag & drop. file is DataReaderFile
  Future<T> fromDroppedFile(file) async {
    final fileExt = getFileExt(file.fileName);
    final XFile xfile = XFile.fromData(await file.readAll());
    if (['png', 'jpg', 'webp', 'jpeg', 'bmp', 'svg'].contains(fileExt)) {
      return ImageModel(
            file: xfile,
            mimeType: 'image/$fileExt',
            filename: file.fileName,
            fileSize: file.fileSize,
          )
          as T;
    } else if (fileExt == 'pdf') {
      return PdfModel(
            file: file,
            mimeType: 'application/pdf',
            fileSize: file.fileSize,
            filename: file.name,
          )
          as T;
    }
    throw 'not supported';
  }

  String getFileExt(String name) {
    return name.split('.').last.toLowerCase();
  }

  T? findRelationData({List included = const [], Map? relation}) {
    final relationData = relation?['data'];
    if (relationData == null || included.isEmpty) {
      return null;
    }
    final data = included.firstWhere(
      (row) =>
          row['type'] == relationData['type'] &&
          row['id'] == relationData['id'],
      orElse: () => null,
    );
    if (data == null) {
      return null;
    }
    return fromJson(data, included: included);
  }

  List<T> findRelationsData({List included = const [], Map? relation}) {
    final relationData = relation?['data'];
    if (relationData == null || included.isEmpty) {
      return [];
    }
    List<T> values = [];
    for (final line in relationData) {
      final data = included.firstWhere(
        (row) => row['type'] == line['type'] && row['id'] == line['id'],
        orElse: () => null,
      );
      if (data != null) {
        values.add(fromJson(data, included: included));
      }
    }
    return values;
  }

  T fromJson(Map<String, dynamic> json, {List included = const []}) {
    var model = initModel(json['type']);
    model.setFromJson(json, included: included);
    return model;
  }
}

class PdfModel extends FileAttachment {
  PdfModel({
    super.createdAt,
    super.updatedAt,
    super.file,
    super.fileSize,
    super.filename,
    super.id,
    super.mimeType,
    super.secureUrl,
    super.signedId,
  });

  @override
  Widget thumbnail({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: .all(.circular(5)),
        border: .all(),
      ),
      child: Center(child: Text('PDF')),
    );
  }

  Future<Uint8List?> obtainBytes(Server server) {
    if (secureUrl != null) {
      return server.download(url: secureUrl, acceptHeader: .pdf);
    } else if (file != null) {
      return file!.readAsBytes();
    } else {
      throw 'file not found';
    }
  }

  @override
  void showPreview(BuildContext context) {
    final Server server = context.read<Server>();
    obtainBytes(server).then((bytes) {
      if (context.mounted && bytes != null) {
        showDialog(
          context: context,
          builder: (context) {
            final navigator = Navigator.of(context);
            final size = MediaQuery.sizeOf(context);
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Center(
                child: Column(
                  children: [
                    Align(
                      alignment: .topRight,
                      child: IconButton.filled(
                        onPressed: () => navigator.pop(),
                        icon: Icon(Icons.close),
                      ),
                    ),
                    SizedBox(
                      width: 1000,
                      height: size.height - 110,
                      child: PdfViewer.data(
                        bytes,
                        sourceName: filename ?? 'file.pdf',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    });
  }
}
