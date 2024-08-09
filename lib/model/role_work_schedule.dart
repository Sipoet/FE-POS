import 'package:fe_pos/model/model.dart';

class RoleWorkSchedule extends Model {
  TimeDay beginWork;
  TimeDay endWork;
  int shift;
  int dayOfWeek;
  int level;
  Date beginActiveAt;
  Date endActiveAt;
  String groupName;
  bool isFlexible;
  RoleWorkSchedule(
      {TimeDay? beginWork,
      TimeDay? endWork,
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
  factory RoleWorkSchedule.fromJson(Map<String, dynamic> json,
      {RoleWorkSchedule? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= RoleWorkSchedule();
    model.id = int.parse(json['id']);
    model.beginWork = TimeDay.parse(attributes['begin_work']);
    model.endWork = TimeDay.parse(attributes['end_work']);
    model.shift = attributes['shift'];
    model.dayOfWeek = attributes['day_of_week'];
    model.groupName = attributes['group_name'];
    model.level = attributes['level'];
    model.beginActiveAt = Date.tryParse(attributes['begin_active_at'] ?? '') ??
        model.beginActiveAt;
    model.endActiveAt =
        Date.tryParse(attributes['end_active_at'] ?? '') ?? model.endActiveAt;
    model.isFlexible = attributes['is_flexible'];
    return model;
  }
}
