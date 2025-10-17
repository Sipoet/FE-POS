import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/query_data.dart';
import 'package:flutter/material.dart';
import 'package:pluralize/pluralize.dart';
export 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/tool/query_data.dart';

final plural = Pluralize();

abstract class Model {
  DateTime? createdAt;
  DateTime? updatedAt;
  Map rawData;
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

  String get path => plural.plural(modelName);
  String get modelName => 'model';

  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    final attributes = json['attributes'];
    id = json['id'];
    createdAt = DateTime.tryParse(attributes['created_at'] ?? '');
    updatedAt = DateTime.tryParse(attributes['updated_at'] ?? '');
    rawData = {'data': json, 'included': included};
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
      } else if (object is Date || object is DateTime) {
        json[key] = object.toIso8601String();
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

  dynamic operator [](key) {
    return toMap()[key];
  }

  void reset() {
    setFromJson(rawData['data'], included: rawData['included']);
  }

  String get modelValue;

  bool get isNewRecord => id == null;
}

abstract class ModelClass<T extends Model> {
  T initModel();

  T? findRelationData({
    List included = const [],
    Map? relation,
  }) {
    final relationData = relation?['data'];
    if (relationData == null || included.isEmpty) {
      return null;
    }
    final data = included.firstWhere(
        (row) =>
            row['type'] == relationData['type'] &&
            row['id'] == relationData['id'],
        orElse: () => null);
    if (data == null) {
      return null;
    }
    return fromJson(data, included: included);
  }

  List<T> findRelationsData({
    List included = const [],
    Map? relation,
  }) {
    final relationData = relation?['data'];
    if (relationData == null || included.isEmpty) {
      return [];
    }
    List<T> values = [];
    for (final line in relationData) {
      final data = included.firstWhere(
          (row) => row['type'] == line['type'] && row['id'] == line['id'],
          orElse: () => null);
      if (data != null) {
        values.add(fromJson(data, included: included));
      }
    }
    return values;
  }

  T fromJson(Map<String, dynamic> json, {List included = const []}) {
    var model = initModel();
    model.setFromJson(json, included: included);
    return model;
  }
}

mixin SaveNDestroyModel on Model {
  Future<bool> save(Server server) async {
    Future request;
    if (isNewRecord) {
      request = server.post(path, body: {
        'data': {'type': modelName, 'attributes': toJson()}
      });
    } else {
      request = server.put("$path/$id", body: {
        'data': {'type': modelName, 'attributes': toJson()}
      });
    }
    return request.then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        setFromJson(response.data['data'],
            included: response.data['included'] ?? []);
        return true;
      } else if (response.statusCode == 409) {
        _errors = response.data['errors'];
      } else {
        _errors = [response.data.toString()];
      }
      return false;
    }, onError: (error) {
      _errors = [error.toString()];
      return false;
    });
  }

  Future<bool> destroy(Server server) async {
    return server.delete("$path/$id").then((response) {
      if (response.statusCode == 200) {
        _flagDestroyed = true;
        return true;
      } else if (response.statusCode == 409) {
        _errors = response.data['errors'];
      } else {
        _errors = [response.data.toString()];
      }
      return false;
    }, onError: (error) {
      _errors = [error.toString()];
      return false;
    });
  }
}

mixin FindModel<T extends Model> on ModelClass<T> {
  Future<T?> find(Server server, dynamic id) async {
    final path = initModel().path;
    return server.get("$path/${id.toString()}").then((response) {
      if (response.statusCode == 200) {
        return fromJson(response.data['data'],
            included: response.data['included'] ?? []);
      }
      return null;
    }, onError: (error) {
      debugPrint(error.toString());
      return null;
    });
  }

  Map<String, dynamic> _encodeQuery(QueryData queryData) {
    Map<String, dynamic> result = {
      'sort': _encodeSorts(queryData.sorts),
      'page[page]': queryData.page.toString(),
      'page[limit]': queryData.limit.toString(),
    };
    for (final filter in queryData.filters) {
      final entry = filter.toJson();
      result[entry.key] = entry.value;
    }

    return result;
  }

  String _encodeSorts(List<SortData> sorts) {
    List result = [];
    for (final sort in sorts) {
      result.add("'${sort.isAscending ? '' : '-'}${sort.key}'");
    }
    return result.join(',');
  }

  Future<List<T>?> finds(Server server, QueryData queryData) async {
    final path = initModel().path;
    final param = _encodeQuery(queryData);
    return server.get(path, queryParam: param).then((response) {
      if (response.statusCode == 200) {
        return response.data['data']
            .map<T>((json) =>
                fromJson(json, included: response.data['included'] ?? []))
            .toList();
      }
      return null;
    }, onError: (error) {
      debugPrint(error.toString());
      return null;
    });
  }
}
