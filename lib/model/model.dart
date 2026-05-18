import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/image_model.dart';
import 'package:fe_pos/tool/query_data.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/tool/query_data.dart';

final jsonEncoder = JsonEncoder();

abstract class Model with ChangeNotifier {
  DateTime? createdAt;
  DateTime? updatedAt;
  Map<String, dynamic> rawData;
  Map<String, dynamic> altData = {};
  dynamic id;

  List<String> _errors = [];
  bool _flagDestroyed = false;
  void flagDestroy() {
    _flagDestroyed = true;
  }

  void unflagDestroy() {
    _flagDestroyed = false;
  }

  Model({this.createdAt, this.updatedAt, this.id, this.rawData = const {}});

  bool get isDestroyed => _flagDestroyed;

  List<String> get errors => _errors;

  String get path => modelName.toPluralize();
  String get modelName => runtimeType.toString().toSnakeCase();

  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    final attributes = json['attributes'] ?? {};
    id = int.tryParse(json['id'] ?? '') ?? json['id'];
    createdAt = DateTime.tryParse(attributes?['created_at'] ?? '');
    updatedAt = DateTime.tryParse(attributes?['updated_at'] ?? '');
    rawData = {'data': json, 'included': included};
    notifyListeners();
  }

  Future<bool> refresh(Server server, {List<String> include = const []}) {
    if (isNewRecord) {
      return Future.value(false);
    }
    return server
        .get(
          "$path/${id.toString()}",
          queryParam: {'included': include.join(',')},
        )
        .then(
          (response) {
            if (response.statusCode == 200) {
              setFromJson(
                response.data['data'],
                included: response.data['included'] ?? [],
              );
              return true;
            }
            return false;
          },
          onError: (error) {
            debugPrint(error.toString());
            return false;
          },
        );
  }

  @override
  bool operator ==(Object other) {
    if (other is Model) {
      return toJson() == other.toJson() && runtimeType == other.runtimeType;
    }
    return false;
  }

  @override
  int get hashCode => asJson().hashCode;

  int compareTo(Model b) {
    return modelValue.compareTo(b.modelValue);
  }

  Map<String, dynamic> asMap() {
    Map<String, dynamic> value = toMap();
    if (altData.isNotEmpty) {
      value.addAll(altData);
    }
    if (createdAt != null) {
      value['created_at'] = createdAt;
    }
    if (createdAt != null) {
      value['updated_at'] = updatedAt;
    }
    if (id != null) {
      value['id'] = id;
    }
    value['_destroy'] = _flagDestroyed;
    return value;
  }

  String toJson() => jsonEncoder.convert(asJson());

  Map<String, dynamic> asJson() {
    Map<String, dynamic> json = asMap();
    for (String key in json.keys.toList()) {
      var object = json[key];
      json[key] = convert(object);
    }
    return json;
  }

  dynamic convert(Object? object, {List<String> parentKey = const []}) {
    if (object is Money) {
      return object.value;
    } else if (object is Percentage) {
      return object.value * 100;
    } else if (object is Date) {
      return object.toIso8601String();
    } else if (object is DateTime) {
      return object.toUtc().toIso8601String();
    } else if (object is Enum) {
      return object.toString();
    } else if (object is String) {
      return object.trim();
    } else if (object is Model) {
      return object.id;
    } else if (object is File) {
      return MultipartFile.fromFileSync(object.path);
    } else if (object is ImageModel) {
      return object.asMapData();
    } else if (object is TimeOfDay) {
      return object.asJson();
    } else if (object is Iterable) {
      return object.map((e) => convert(e)).toList();
    } else {
      return object;
    }
  }

  Map<String, dynamic> toMap();

  dynamic operator [](String key) {
    return asMap()[key];
  }

  operator []=(String key, dynamic value) {
    altData[key] = value;
  }

  void reset() {
    setFromJson(rawData['data'] ?? {}, included: rawData['included'] ?? []);
    notifyListeners();
  }

  String get modelValue => id.toString();
  String? get valueDescription => null;

  String get valueWithDescription =>
      [modelValue, valueDescription].where((e) => e != null).join(' - ');

  bool get isNewRecord => id == null || (id is String && id.isEmpty);
}

abstract class ModelClass<T extends Model> {
  T initModel();

  String get path => initModel().path;

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

  HasManyRelationShip<T> findRelationsData2({
    List included = const [],
    Map? relation,
    required String foreignKey,
    dynamic foreignId,
  }) {
    QueryRequest queryRequest = QueryRequest(
      filters: [ComparisonFilterData(key: foreignKey, value: foreignId)],
    );
    return HasManyRelationShip<T>(
      getData: (server) =>
          finds(server, queryRequest).then((result) => result.models),
      values: findRelationsData(included: included, relation: relation),
    );
  }

  T fromJson(Map<String, dynamic> json, {List included = const []}) {
    var model = initModel();
    model.setFromJson(json, included: included);
    return model;
  }

  Future<T?> find(Server server, dynamic id) async {
    return server
        .get("$path/${Uri.encodeComponent(id.toString())}")
        .then(
          (response) {
            if (response.statusCode == 200) {
              return fromJson(
                response.data['data'],
                included: response.data['included'] ?? [],
              );
            }
            return null;
          },
          onError: (error) {
            debugPrint(error.toString());
            return null;
          },
        );
  }

  Future<QueryResponse<T>> finds(
    Server server,
    QueryRequest queryRequest,
  ) async {
    final param = queryRequest.toQueryParam();
    return server
        .get(path, queryParam: param, cancelToken: queryRequest.cancelToken)
        .then(
          (response) {
            if (response.statusCode != 200) {
              throw 'error: ${response.data.toString()}';
            }
            final data = response.data;
            return QueryResponse(
              metadata: data['meta'],
              models: data['data']
                  .map<T>(
                    (json) => fromJson(json, included: data['included'] ?? []),
                  )
                  .toList(),
            );
          },
          onError: (error) {
            if (error is DioException) {
              switch (error.type) {
                case DioExceptionType.badResponse:
                case DioExceptionType.connectionError:
                case DioExceptionType.sendTimeout:
                  throw 'Gagal Koneksi Server. Periksa Koneksi internet anda';
                case DioExceptionType.connectionTimeout:
                case DioExceptionType.receiveTimeout:
                  throw 'Server Sibuk. Cobalah lagi beberapa saat';
                default:
                  throw 'koneksi error';
              }
            }
            debugPrint(error.toString());
            return QueryResponse();
          },
        );
  }
}

mixin SaveNDestroyModel on Model {
  void asFormData({
    required FormData formData,
    required Map<String, dynamic> data,
    List<String> parentKey = const [],
  }) {
    for (String key in data.keys.toList()) {
      var object = data[key];
      String formKey = formDataKey(parentKey + [key]);
      if (object == null) {
        formData.fields.add(MapEntry(formKey, ''));
      } else if (object is Money) {
        formData.fields.add(MapEntry(formKey, object.value.toString()));
      } else if (object is Percentage) {
        double value = object.value * 100;
        formData.fields.add(MapEntry(formKey, value.toString()));
      } else if (object is Date) {
        formData.fields.add(MapEntry(formKey, object.toIso8601String()));
      } else if (object is DateTime) {
        formData.fields.add(
          MapEntry(formKey, object.toUtc().toIso8601String()),
        );
      } else if (object is Enum) {
        object.toString();
        formData.fields.add(MapEntry(formKey, object.toString()));
      } else if (object is String) {
        formData.fields.add(MapEntry(formKey, object.trim()));
      } else if (object is Model) {
        formData.fields.add(MapEntry(formKey, object.id.toString()));
      } else if (object is File) {
        formData.files.add(
          MapEntry(formKey, MultipartFile.fromFileSync(object.path)),
        );
      } else if (object is ImageModel) {
        final value = object.asMapData();
        if (value is MultipartFile) {
          formData.files.add(MapEntry(formKey, value));
        } else if (object is Map) {
          formData.fields.add(MapEntry(formKey, value.toString()));
        } else {
          formData.fields.add(MapEntry(formKey, ''));
        }
      } else if (object is TimeOfDay) {
        formData.fields.add(MapEntry(formKey, object.asJson()));
      } else if (object is List || object is Set) {
        for (var row in object) {
          if (row is MultipartFile) {
            formData.files.add(MapEntry("$formKey[]", row));
          } else if (row is Map<String, dynamic>) {
            asFormData(
              data: row,
              formData: formData,
              parentKey: parentKey + [key, ''],
            );
          } else {
            asFormData(
              data: {'': row},
              formData: formData,
              parentKey: parentKey + [key],
            );
          }
        }
      } else {
        formData.fields.add(MapEntry(formKey, object.toString()));
      }
    }
  }

  String formDataKey(List<String> keys) {
    String newKeys = keys.first;
    if (keys.length == 1) {
      return newKeys;
    }
    for (var key in keys.sublist(1, keys.length)) {
      newKeys += '[$key]';
    }
    return newKeys;
  }

  Future<bool> save(
    Server server, {
    Map<String, dynamic>? includeAttributes,
    HttpContentType contentType = .json,
  }) async {
    Future request;
    dynamic body;
    Map<String, dynamic> attributes = asJson();
    if (includeAttributes != null) {
      attributes.addAll(includeAttributes);
    }

    if (isNewRecord) {
      if (contentType == .json) {
        body = {
          'data': {'type': modelName, 'attributes': attributes},
        };
      } else {
        body = FormData();
        asFormData(formData: body, data: attributes, parentKey: ['data']);
        body.fields.add(MapEntry('data[type]', modelName));
      }
      request = server.post(path, body: body, contentType: contentType);
    } else {
      if (contentType == .json) {
        body = {
          'data': {'id': id, 'type': modelName, 'attributes': attributes},
        };
      } else {
        body = FormData();
        asFormData(
          formData: body,
          data: attributes,
          parentKey: ['data', 'attributes'],
        );
        body.fields.add(MapEntry('data[type]', modelName));
        body.fields.add(MapEntry('data[id]', id.toString()));
      }
      request = server.put("$path/$id", body: body, contentType: contentType);
    }
    return request.then(
      (response) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          setFromJson(
            response.data['data'],
            included: response.data['included'] ?? [],
          );
          return true;
        } else if (response.statusCode == 409) {
          _errors =
              response.data['errors'].map<String>((e) => e.toString()).toList()
                  as List<String>;
        } else {
          _errors = <String>[response.data.toString()];
        }
        return false;
      },
      onError: (error) {
        _errors = [error.toString()];
        return false;
      },
    );
  }

  Future<bool> destroy(Server server) async {
    return server
        .delete("$path/$id")
        .then(
          (response) {
            if (response.statusCode == 200) {
              _flagDestroyed = true;
              return true;
            } else if (response.statusCode == 409) {
              _errors = response.data['errors'];
            } else {
              _errors = [response.data.toString()];
            }
            return false;
          },
          onError: (error) {
            _errors = [error.toString()];
            return false;
          },
        );
  }
}

class HasManyRelationShip<T extends Model> extends ChangeNotifier
    with IterableMixin<T> {
  List<T> values;
  Future<List<T>> Function(Server server) getData;
  HasManyRelationShip({this.values = const [], required this.getData});
  Future<List<T>> reload(Server server) async {
    values = await getData(server);
    notifyListeners();
    return values;
  }

  @override
  Iterator<T> get iterator => values.iterator;
}

class BelongsToRelationShip<T extends Model> {
  T? _value;
  Server server;
  Future<T> Function(Server server) getData;
  BelongsToRelationShip({T? value, required this.server, required this.getData})
    : _value = value;
  FutureOr<T?> reload() async {
    _value = await getData(server);
    return _value!;
  }
}
