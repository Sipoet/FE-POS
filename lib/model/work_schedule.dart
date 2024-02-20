import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class WorkSchedule extends Model {
  String beginWork;
  String endWork;
  int shift;
  int dayOfWeek;
  int? id;
  WorkSchedule(
      {required this.beginWork,
      required this.endWork,
      this.dayOfWeek = 1,
      this.shift = 1,
      this.id});

  @override
  Map<String, dynamic> toMap() => {
        'begin_work': beginWork,
        'end_work': endWork,
        'shift': shift,
        'day_of_week': dayOfWeek,
      };

  @override
  factory WorkSchedule.fromJson(Map<String, dynamic> json,
      {WorkSchedule? model}) {
    var attributes = json['attributes'];
    model ??= WorkSchedule(beginWork: '', endWork: '');
    model.id = int.parse(json['id']);
    model.beginWork = attributes['begin_work'];
    model.endWork = attributes['end_work'];
    model.shift = attributes['shift'];
    model.dayOfWeek = attributes['day_of_week'];
    return model;
  }
}
