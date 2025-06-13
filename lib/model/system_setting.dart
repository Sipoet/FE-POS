import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/user.dart';
export 'package:fe_pos/model/user.dart';

enum SettingValueType {
  string,
  number,
  json,
  date,
  boolean,
  datetime,
  time;

  static SettingValueType fromString(value) {
    switch (value) {
      case 'string':
        return string;
      case 'number':
        return number;
      case 'json':
        return json;
      case 'date':
        return date;
      case 'datetime':
        return datetime;
      case 'time':
        return time;
      case 'boolean':
        return boolean;
      default:
        throw ('Invalid setting value type $value');
    }
  }

  String humanize() {
    switch (this) {
      case string:
        return 'string';
      case number:
        return 'number';
      case json:
        return 'json';
      case date:
        return 'date';
      case datetime:
        return 'datetime';
      case time:
        return 'time';
      case boolean:
        return 'boolean';
    }
  }

  @override
  String toString() {
    switch (this) {
      case string:
        return 'string';
      case number:
        return 'number';
      case json:
        return 'json';
      case date:
        return 'date';
      case datetime:
        return 'datetime';
      case time:
        return 'time';
      case boolean:
        return 'boolean';
    }
  }
}

class SystemSetting extends Model {
  String key;
  SettingValueType valueType;
  dynamic value;
  int? userId;
  User? user;

  SystemSetting({
    this.key = '',
    this.value,
    this.userId,
    this.valueType = SettingValueType.string,
    this.user,
    super.id,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() => {
        'key_name': key,
        'user': user,
        'value_type': valueType.toString(),
        'value': value,
        'user_id': userId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  factory SystemSetting.fromJson(Map<String, dynamic> json,
      {SystemSetting? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= SystemSetting();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.key = attributes['key_name'];
    model.value = attributes['value'];
    if (attributes['value_type'] != null) {
      model.valueType = SettingValueType.fromString(attributes['value_type']);
    }
    if (model.value is String) {
      if (model.valueType == SettingValueType.date) {
        model.value = Date.tryParse(model.value);
      } else if (model.valueType == SettingValueType.datetime) {
        model.value = DateTime.tryParse(model.value);
      } else if (model.valueType == SettingValueType.time) {
        model.value = TimeDay.tryParse(model.value);
      }
    }
    model.userId = attributes['user_id'];
    model.user = Model.findRelationData<User>(
            relation: json['relationships']?['user'],
            included: included,
            convert: User.fromJson) ??
        model.user;
    return model;
  }

  @override
  String get modelValue => "$key : ${value.toString()}";
}
