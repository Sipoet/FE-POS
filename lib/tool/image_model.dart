import 'package:fe_pos/tool/file_attachment.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/widget/protected_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageModel extends ImageProvider<Uri> implements FileAttachment {
  @override
  XFile? file;
  @override
  String? mimeType;
  @override
  String? filename;
  @override
  String? secureUrl;
  @override
  String? signedId;
  @override
  int? fileSize;
  @override
  int? id;
  @override
  DateTime? createdAt;
  @override
  DateTime? updatedAt;
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

  @override
  bool get isAttached => id != null;
  @override
  bool get isDestroyed => _flagDestroyed;

  @override
  void flagDestroy() {
    _flagDestroyed = true;
  }

  @override
  void unflagDestroy() {
    _flagDestroyed = false;
  }

  @override
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

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'] ?? {};
    secureUrl = attributes['secure_url'];
    signedId = attributes['signed_id'];
    mimeType = attributes['content_type'];
    id = int.tryParse(json['id'] ?? '');
    createdAt = DateTime.tryParse(attributes['created_at'] ?? '');
    updatedAt = DateTime.tryParse(attributes['updated_at'] ?? '');
  }

  @override
  ImageStreamCompleter loadImage(Uri key, ImageDecoderCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();
    if (file != null) {
      return MultiFrameImageStreamCompleter(
        codec: file!
            .readAsBytes()
            .then((bytes) {
              _setSizeFromBytes(bytes);
              return ui.ImmutableBuffer.fromUint8List(bytes);
            })
            .whenComplete(chunkEvents.close)
            .then(decode),
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

  @override
  Widget thumbnail({double? width, double? height}) {
    return ProtectedImage(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          border: .all(width: 2),
          borderRadius: .all(.circular(10)),
          image: DecorationImage(
            image: ResizeImage(
              this,
              width: width?.toInt(),
              height: height?.toInt(),
            ),
            fit: .contain,
          ),
        ),
      ),
    );
  }

  @override
  void showPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              ProtectedImage(child: Image(image: this)),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton.filled(
                  onPressed: () => navigator.pop(),
                  icon: Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
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
