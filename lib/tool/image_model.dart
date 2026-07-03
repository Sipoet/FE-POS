import 'package:fe_pos/model/server.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageModel extends ImageProvider<Uri> {
  String? secureUrl;
  String? signedId;
  XFile? file;
  String? mimeType;
  String? filename;
  int? id;
  bool _flagDestroyed = false;
  ui.Size? size;
  Dio dio =
      Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 5),
            validateStatus: (int? status) {
              if (status != null && status <= 308 && status >= 200) {
                return true;
              }
              return [409].contains(status);
            },
          ),
        )
        ..httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () {
            final HttpClient client = HttpClient(
              context: SecurityContext(withTrustedRoots: false),
            );
            // ignore bad certificate
            client.badCertificateCallback = (cert, host, port) => true;
            return client;
          },
        );

  HttpContentType? get contentType {
    try {
      return HttpContentType.fromString(mimeType);
    } catch (error) {
      return null;
    }
  }

  int? fileSize;

  ImageModel({
    this.id,
    this.signedId,
    this.secureUrl,
    this.fileSize,
    this.file,
    this.mimeType,
    this.filename,
  }) : assert(
         !(id != null && secureUrl == null),
         'secureUrl must filled if id not null',
       );
  @override
  Future<Uri> obtainKey(ImageConfiguration configuration) {
    if (secureUrl != null) {
      final Uri result = Uri.parse(secureUrl!).replace(
        queryParameters: <String, String>{
          'dpr': '${configuration.devicePixelRatio}',
          'locale': '${configuration.locale?.toLanguageTag()}',
          'platform': '${configuration.platform?.name}',
          'width': '${configuration.size?.width}',
          'height': '${configuration.size?.height}',
          'bidi': '${configuration.textDirection?.name}',
        },
      );
      return Future<Uri>.syncValue(result);
    } else if (file != null) {
      return Future<Uri>.sync(() {
        return file!.readAsBytes().then((bytes) {
          return Uri.dataFromBytes(
            bytes.toList(),
            mimeType: mimeType ?? "application/octet-stream",
          );
        });
      });
    } else {
      throw 'image not found';
    }
  }

  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'] ?? {};
    secureUrl = attributes['secure_url'];
    signedId = attributes['signed_id'];
    mimeType = attributes['content_type'];
    id = int.tryParse(json['id'] ?? '');
  }

  bool get isAttached => id != null;

  void flagDestroy() {
    _flagDestroyed = true;
  }

  void unflagDestroy() {
    _flagDestroyed = false;
  }

  bool get isDestroyed => _flagDestroyed;

  dynamic asMapData() {
    if (id == null) {
      if (file == null) {
        return null;
      }
      return MultipartFile.fromFileSync(
        file!.path,
        filename: filename,
        contentType: mimeType == null ? null : .parse(mimeType!),
      );
    } else {
      return {'id': id, '_destroy': _flagDestroyed, 'type': 'image'};
    }
    // if (secureUrl != null) {
    //   final uri = Uri.parse(secureUrl!);

    //   String ext = contentType?.extName ?? secureUrl!.split('.').last;
    //   final tempFile = await TempFile.create(ext);
    //   final response = await dio.downloadUri(uri, tempFile.path);
    //   if (response.statusCode == 200) {
    //     bytes = response.data;
    //     return MultipartFile.fromBytes(
    //       response.data,
    //       filename: filename,
    //       contentType: contentType == null
    //           ? null
    //           : .parse(contentType.toString()),
    //     );
    //   }
    //   return Future.error(Exception('failed download image'));
    // }
    // return Future.error(Exception('at least secureUrl or bytes filled'));
  }

  @override
  ImageStreamCompleter loadImage(Uri key, ImageDecoderCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();
    if (file != null) {
      file?.readAsBytes().then(_setSizeFromBytes);
      return MultiFrameImageStreamCompleter(
        codec: ui.ImmutableBuffer.fromFilePath(file!.path).then(decode),
        chunkEvents: chunkEvents.stream,
        scale: 1.0,
        debugLabel: '"key"',
        informationCollector: () => <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<Uri>('URL', key),
        ],
      );
    }
    return MultiFrameImageStreamCompleter(
      codec: dio
          .getUri(key, options: Options(responseType: .bytes))
          .then<Uint8List>((response) {
            return response.data;
          })
          .catchError((Object e, StackTrace stack) {
            scheduleMicrotask(() {
              PaintingBinding.instance.imageCache.evict(key);
            });
            return Future<Uint8List>.error(e, stack);
          })
          .whenComplete(chunkEvents.close)
          .then<ui.ImmutableBuffer>((bytes) {
            _setSizeFromBytes(bytes);
            return ui.ImmutableBuffer.fromUint8List(bytes);
          })
          .then<ui.Codec>(decode),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      debugLabel: '"key"',
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<Uri>('URL', key),
      ],
    );
  }

  @override
  String toString() => '${objectRuntimeType(this, 'ImageModel')}("$id")';

  void _setSizeFromBytes(Uint8List bytes) async {
    ui.decodeImageFromList(bytes, (decodedImage) {
      size = ui.Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
    });
  }
}

class ImageModelClass {
  ImageModel initModel() => ImageModel();
  ImageModel? findRelationData({List included = const [], Map? relation}) {
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

  List<ImageModel> findRelationsData({
    List included = const [],
    Map? relation,
  }) {
    final relationData = relation?['data'];
    if (relationData == null || included.isEmpty) {
      return [];
    }
    List<ImageModel> values = [];
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

  ImageModel fromJson(Map<String, dynamic> json, {List included = const []}) {
    var model = initModel();
    model.setFromJson(json, included: included);
    return model;
  }
}
