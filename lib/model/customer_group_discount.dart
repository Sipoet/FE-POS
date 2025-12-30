import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/customer_group.dart';
export 'package:fe_pos/model/customer_group.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum CustomerGroupDiscountPeriodType implements EnumTranslation {
  activePeriod,
  dayOfMonth,
  dayOfWeek,
  weekOfMonth;

  @override
  String toString() {
    switch (this) {
      case activePeriod:
        return 'active_period';
      case dayOfMonth:
        return 'day_of_month';
      case dayOfWeek:
        return 'day_of_week';
      case weekOfMonth:
        return 'week_of_month';
    }
  }

  static CustomerGroupDiscountPeriodType fromString(value) {
    switch (value) {
      case 'active_period':
        return activePeriod;
      case 'day_of_month':
        return dayOfMonth;
      case 'day_of_week':
        return dayOfWeek;
      case 'week_of_month':
        return weekOfMonth;
      default:
        throw 'not valid payslip status';
    }
  }

  @override
  String humanize() {
    switch (this) {
      case activePeriod:
        return 'Periode Aktif';
      case dayOfMonth:
        return 'Bulanan';
      case dayOfWeek:
        return 'Mingguan';
      case weekOfMonth:
        return 'Minggu dalam Bulan';
    }
  }
}

class CustomerGroupDiscount extends Model {
  CustomerGroupDiscountPeriodType periodType;
  Percentage discountPercentage;
  Date startActiveDate;
  Date endActiveDate;
  int level;
  int? variable1;
  int? variable2;
  int? variable3;
  int? variable4;
  int? variable5;
  int? variable6;
  int? variable7;
  CustomerGroup customerGroup;

  CustomerGroupDiscount(
      {this.periodType = CustomerGroupDiscountPeriodType.activePeriod,
      this.discountPercentage = const Percentage(0),
      Date? startActiveDate,
      Date? endActiveDate,
      this.level = 1,
      CustomerGroup? customerGroup,
      this.variable1,
      this.variable2,
      this.variable3,
      this.variable4,
      this.variable5,
      this.variable6,
      this.variable7,
      super.id,
      super.createdAt,
      super.updatedAt})
      : startActiveDate = startActiveDate ?? Date.today(),
        endActiveDate = endActiveDate ?? Date.today(),
        customerGroup = customerGroup ?? CustomerGroup();

  @override
  Map<String, dynamic> toMap() => {
        'discount_percentage': discountPercentage,
        'period_type': periodType,
        'start_active_date': startActiveDate,
        'end_active_date': endActiveDate,
        'level': level,
        'customer_group': customerGroup,
        'customer_group_code': customerGroupCode,
        'variable1': variable1,
        'variable2': variable2,
        'variable3': variable3,
        'variable4': variable4,
        'variable5': variable5,
        'variable6': variable6,
        'variable7': variable7,
        'customer_group.grup': customerGroup.name,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
  String get customerGroupCode => customerGroup.code;
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    discountPercentage = Percentage.parse(attributes['discount_percentage']);
    periodType =
        CustomerGroupDiscountPeriodType.fromString(attributes['period_type']);
    startActiveDate = Date.parse(attributes['start_active_date']);
    endActiveDate = Date.parse(attributes['end_active_date']);
    level = attributes['level'];
    variable1 = attributes['variable1'];
    variable2 = attributes['variable2'];
    variable3 = attributes['variable3'];
    variable4 = attributes['variable4'];
    variable5 = attributes['variable5'];
    variable6 = attributes['variable6'];
    variable7 = attributes['variable7'];
    customerGroup = CustomerGroupClass().findRelationData(
            included: included,
            relation: json['relationships']?['customer_group']) ??
        customerGroup;
  }

  @override
  String get modelValue => customerGroupCode;
}

class CustomerGroupDiscountClass extends ModelClass<CustomerGroupDiscount> {
  @override
  CustomerGroupDiscount initModel() => CustomerGroupDiscount();
}
