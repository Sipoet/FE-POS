import 'package:fe_pos/model/model.dart';

enum DiscountDetailType implements EnumTranslation {
  percentage,
  nominal;

  @override
  String humanize() {
    switch (this) {
      case percentage:
        return 'Persen';
      case nominal:
        return 'Nominal';
    }
  }

  @override
  String toString() {
    switch (this) {
      case percentage:
        return 'Purchase::PercentageDiscountCalculator';
      case nominal:
        return 'Purchase::NominalDiscountCalculator';
    }
  }

  static DiscountDetailType fromString(String value) {
    switch (value) {
      case 'percentage':
        return percentage;
      case 'nominal':
        return nominal;
      case 'Purchase::PercentageDiscountCalculator':
        return percentage;
      case 'Purchase::NominalDiscountCalculator':
        return nominal;
      default:
        throw '$value invalid discount detail type';
    }
  }
}

class DiscountDetail extends Model {
  double value;
  DiscountDetailType type;
  DiscountDetail({this.type = .percentage, this.value = 0});
  @override
  Map<String, dynamic> toMap() => {'type': type, 'discount': value};

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    value = double.tryParse(attributes['discount'].toString()) ?? 0;

    type = DiscountDetailType.fromString(attributes['type']);
  }
}

class DiscountDetailClass extends ModelClass<DiscountDetail> {
  @override
  DiscountDetail initModel() => DiscountDetail();
}
