import 'package:fe_pos/model/model.dart';
import 'package:flutter/material.dart' show TimeOfDay;

class RoleWorkSchedule extends Model {
  TimeOfDay beginWork;
  TimeOfDay endWork;
  int shift;
  int dayOfWeek;
  int level;
  Date beginActiveAt;
  Date endActiveAt;
  String groupName;
  bool isFlexible;
  RoleWorkSchedule(
      {TimeOfDay? beginWork,
      TimeOfDay? endWork,
      Date? beginActiveAt,
      Date? endActiveAt,
      this.groupName = '',
      this.dayOfWeek = 1,
      this.shift = 1,
      this.level = 1,
      this.isFlexible = false,
      super.id})
      : beginActiveAt = beginActiveAt ?? Date.today(),
        endActiveAt = endActiveAt ?? Date.today(),
        beginWork = beginWork ?? TimeDay.now(),
        endWork = endWork ?? TimeDay.now();

  @override
  Map<String, dynamic> toMap() => {
        'begin_work': beginWork.format24Hour(),
        'end_work': endWork.format24Hour(),
        'shift': shift,
        'day_of_week': dayOfWeek,
        'group_name': groupName,
        'begin_active_at': beginActiveAt,
        'end_active_at': endActiveAt,
        'level': level,
        'is_flexible': isFlexible,
      };

  @override
  String get modelName => 'role_work_schedule';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    beginWork = TimeDay.parse(attributes['begin_work']);
    endWork = TimeDay.parse(attributes['end_work']);
    shift = attributes['shift'];
    dayOfWeek = attributes['day_of_week'];
    groupName = attributes['group_name'];
    level = attributes['level'];
    beginActiveAt =
        Date.tryParse(attributes['begin_active_at'] ?? '') ?? beginActiveAt;
    endActiveAt =
        Date.tryParse(attributes['end_active_at'] ?? '') ?? endActiveAt;
    isFlexible = attributes['is_flexible'];
  }

  @override
  String get modelValue => id.toString();
}

class RoleWorkScheduleClass extends ModelClass<RoleWorkSchedule> {
  @override
  RoleWorkSchedule initModel() => RoleWorkSchedule();
}
