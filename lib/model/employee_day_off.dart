import 'package:fe_pos/model/model.dart';

enum ActiveWeekDayOff implements EnumTranslation {
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

  static ActiveWeekDayOff fromString(value) {
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

class EmployeeDayOff extends Model {
  int dayOfWeek;
  ActiveWeekDayOff activeWeek;

  EmployeeDayOff({
    this.dayOfWeek = 1,
    super.id,
    this.activeWeek = ActiveWeekDayOff.allWeek,
  });

  @override
  Map<String, dynamic> toMap() => {
        'active_week': activeWeek,
        'day_of_week': dayOfWeek,
      };

  @override
  String get modelName => 'employee_day_of';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    activeWeek = ActiveWeekDayOff.fromString(attributes['active_week']);
    dayOfWeek = attributes['day_of_week'];
  }

  @override
  String get modelValue => "${dayOfWeek.toString()} - ${activeWeek.toString()}";
}

class EmployeeDayOffClass extends ModelClass<EmployeeDayOff> {
  @override
  EmployeeDayOff initModel() => EmployeeDayOff();
}
