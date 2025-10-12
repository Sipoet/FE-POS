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
  String get modelName => 'system_setting';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    key = attributes['key_name'];
    value = attributes['value'];
    if (attributes['value_type'] != null) {
      valueType = SettingValueType.fromString(attributes['value_type']);
    }
    if (value is String) {
      if (valueType == SettingValueType.date) {
        value = Date.tryParse(value);
      } else if (valueType == SettingValueType.datetime) {
        value = DateTime.tryParse(value);
      } else if (valueType == SettingValueType.time) {
        value = TimeDay.tryParse(value);
      }
    }
    userId = attributes['user_id'];
    user = UserClass().findRelationData(
          relation: json['relationships']?['user'],
          included: included,
        ) ??
        user;
  }

  @override
  String get modelValue => "$key : ${value.toString()}";
}

class SystemSettingClass extends ModelClass<SystemSetting> {
  @override
  SystemSetting initModel() => SystemSetting();
}
