import 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/tool/custom_type.dart';

abstract class Model {
  dynamic id;
  DateTime? createdAt;
  DateTime? updatedAt;
  Map rawData;
  bool _flagDestroyed = false;
  Model({this.createdAt, this.updatedAt, this.id, this.rawData = const {}});
  Map<String, dynamic> toMap();

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

  bool get isDestroyed => _flagDestroyed;

  void flagDestroy() {
    _flagDestroyed = true;
  }

  void unflagDestroy() {
    _flagDestroyed = false;
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

  dynamic operator [](key) {
    return toMap()[key];
  }

  String get modelValue;

  bool get isNewRecord => id == null;

  static void fromModel(Model model, Map attributes) {
    model.createdAt = DateTime.tryParse(attributes['created_at'] ?? '');
    model.updatedAt = DateTime.tryParse(attributes['updated_at'] ?? '');
    model.rawData = attributes;
  }

  static T? findRelationData<T extends Model>(
      {required List included,
      Map? relation,
      required T Function(Map<String, dynamic>, {List included}) convert}) {
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
    return convert(data, included: included);
  }

  static List<T> findRelationsData<T extends Model>(
      {required List included,
      Map? relation,
      required T Function(Map<String, dynamic>, {List included}) convert}) {
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
        values.add(convert(data, included: included));
      }
    }
    return values;
  }
}

abstract class ModelClass {
  Model fromJson(Map<String, dynamic> json, {List included = const []});
}
