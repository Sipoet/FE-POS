import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum ActiveWeekWorkSchedule implements EnumTranslation {
  allWeek,
  oddWeek,
  evenWeek,
  firstWeekOfMonth,
  lastWeekOfMonth;

  @override
  String toString() {
    switch (this) {
      case allWeek:
        return 'all_week';
      case oddWeek:
        return 'odd_week';
      case evenWeek:
        return 'even_week';
      case firstWeekOfMonth:
        return 'first_week_of_month';
      case lastWeekOfMonth:
        return 'last_week_of_month';
    }
  }

  static ActiveWeekWorkSchedule fromString(value) {
    switch (value) {
      case 'all_week':
        return allWeek;
      case 'odd_week':
        return oddWeek;
      case 'even_week':
        return evenWeek;
      case 'first_week_of_month':
        return firstWeekOfMonth;
      case 'last_week_of_month':
        return lastWeekOfMonth;
      default:
        throw 'invalid value active week $value';
    }
  }

  @override
  String humanize() {
    switch (this) {
      case allWeek:
        return 'Semua';
      case oddWeek:
        return 'Ganjil';
      case evenWeek:
        return 'Genap';
      case firstWeekOfMonth:
        return 'Minggu Pertama per bulan';
      case lastWeekOfMonth:
        return 'Minggu terakhir per bulan';
    }
  }
}

class WorkSchedule extends Model {
  String beginWork;
  String endWork;
  int shift;
  int dayOfWeek;
  ActiveWeekWorkSchedule activeWeek;
  WorkSchedule(
      {this.beginWork = '',
      this.endWork = '',
      this.dayOfWeek = 1,
      this.shift = 1,
      this.activeWeek = ActiveWeekWorkSchedule.allWeek,
      super.id});

  @override
  Map<String, dynamic> toMap() => {
        'begin_work': beginWork,
        'end_work': endWork,
        'shift': shift,
        'day_of_week': dayOfWeek,
        'active_week': activeWeek,
      };

  @override
  String get modelName => 'work_schedule';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    beginWork = attributes['begin_work'];
    endWork = attributes['end_work'];
    shift = attributes['shift'];
    dayOfWeek = attributes['day_of_week'];
    activeWeek = ActiveWeekWorkSchedule.fromString(attributes['active_week']);
  }

  @override
  String get modelValue => id.toString();
}

class WorkScheduleClass extends ModelClass<WorkSchedule> {
  @override
  WorkSchedule initModel() => WorkSchedule();
}
