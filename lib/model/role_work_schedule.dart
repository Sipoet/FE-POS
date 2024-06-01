import 'package:fe_pos/model/model.dart';

class RoleWorkSchedule extends Model {
  String beginWork;
  String endWork;
  int shift;
  int dayOfWeek;
  int level;
  Date beginActiveAt;
  Date endActiveAt;
  String groupName;
  RoleWorkSchedule(
      {required this.beginWork,
      required this.endWork,
      Date? beginActiveAt,
      Date? endActiveAt,
      this.groupName = '',
      this.dayOfWeek = 1,
      this.shift = 1,
      this.level = 1,
      super.id})
      : beginActiveAt = beginActiveAt ?? Date.today(),
        endActiveAt = endActiveAt ?? Date.today();

  @override
  Map<String, dynamic> toMap() => {
        'begin_work': beginWork,
        'end_work': endWork,
        'shift': shift,
        'day_of_week': dayOfWeek,
        'group_name': groupName,
        'begin_active_at': beginActiveAt,
        'end_active_at': endActiveAt,
        'level': level,
      };

  @override
  factory RoleWorkSchedule.fromJson(Map<String, dynamic> json,
      {RoleWorkSchedule? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= RoleWorkSchedule(beginWork: '', endWork: '');
    model.id = int.parse(json['id']);
    model.beginWork = attributes['begin_work'];
    model.endWork = attributes['end_work'];
    model.shift = attributes['shift'];
    model.dayOfWeek = attributes['day_of_week'];
    model.groupName = attributes['group_name'];
    model.level = attributes['level'];
    model.beginActiveAt = Date.tryParse(attributes['begin_active_at'] ?? '') ??
        model.beginActiveAt;
    model.endActiveAt =
        Date.tryParse(attributes['end_active_at'] ?? '') ?? model.endActiveAt;
    return model;
  }
}
