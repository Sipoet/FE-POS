import 'package:fe_pos/model/model.dart';

class CustomerGroup extends Model {
  String code;
  String name;
  Percentage discount;
  int level;
  double powerPoint;

  CustomerGroup(
      {this.code = '',
      this.name = '',
      super.id,
      this.level = 1,
      this.powerPoint = 1,
      this.discount = const Percentage(0)});

  @override
  Map<String, dynamic> toMap() => {
        'kgrup': code,
        'grup': name,
        'potongan': discount,
        'levelharga': level,
        'kelipatanpoin': powerPoint,
      };
  @override
  String get modelName => 'customer_group';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    code = attributes['kgrup'] ?? '';
    name = attributes['grup'];
    level = attributes['levelharga'];
    powerPoint = double.tryParse(attributes['kelipatanpoin']) ?? 0;
    discount = Percentage.parse(attributes['potongan']);
  }

  @override
  String get modelValue => "$code - $name";
}

class CustomerGroupClass extends ModelClass<CustomerGroup> {
  @override
  CustomerGroup initModel() => CustomerGroup();
}
