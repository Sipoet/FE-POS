import 'dart:async';
import 'dart:collection';

import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/query_data.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/tool/query_data.dart';

abstract class Model with ChangeNotifier {
  DateTime? createdAt;
  DateTime? updatedAt;
  Map<String, dynamic> rawData;
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
    id = json['id'];
    createdAt = DateTime.tryParse(attributes?['created_at'] ?? '');
    updatedAt = DateTime.tryParse(attributes?['updated_at'] ?? '');
    rawData = {'data': json, 'included': included};
  }

  Future<bool> refresh(Server server) {
    return server
        .get("$path/${id.toString()}")
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

  Map<String, dynamic> asMap() {
    Map<String, dynamic> value = toMap();
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

  Map<String, dynamic> toJson() {
    var json = asMap();
    json.forEach((key, object) {
      if (object is Money) {
        json[key] = object.value;
      } else if (object is Percentage) {
        json[key] = object.value * 100;
      } else if (object is Date) {
        json[key] = object.toIso8601String();
      } else if (object is DateTime) {
        json[key] = object.toUtc().toIso8601String();
      } else if (object is Enum) {
        json[key] = object.toString();
      } else if (object is String) {
        json[key] = object.trim();
      } else if (object is TimeOfDay) {
        json[key] = object.toJson();
      }
    });
    return json;
  }

  Map<String, dynamic> toMap();

  dynamic operator [](String key) {
    return asMap()[key];
  }

  void reset() {
    setFromJson(rawData['data'] ?? {}, included: rawData['included'] ?? []);
    notifyListeners();
  }

  String get modelValue => id.toString();
  String? get valueDescription => null;

  bool get isNewRecord => id == null;
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
        .get("$path/${id.toString()}")
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
            debugPrint(error.toString());
            return QueryResponse();
          },
        );
  }
}

mixin SaveNDestroyModel on Model {
  Future<bool> save(Server server) async {
    Future request;
    if (isNewRecord) {
      request = server.post(
        path,
        body: {
          'data': {'type': modelName, 'attributes': toJson()},
        },
      );
    } else {
      request = server.put(
        "$path/$id",
        body: {
          'data': {
            'id': id.toString(),
            'type': modelName,
            'attributes': toJson(),
          },
        },
      );
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
