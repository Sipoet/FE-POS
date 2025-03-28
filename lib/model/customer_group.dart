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
  factory CustomerGroup.fromJson(Map<String, dynamic> json,
      {CustomerGroup? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= CustomerGroup();
    model.id = json['id'];
    model.code = attributes['kgrup'] ?? '';
    model.name = attributes['grup'];
    model.level = attributes['levelharga'];
    model.powerPoint = double.tryParse(attributes['kelipatanpoin']) ?? 0;
    model.discount = Percentage.parse(attributes['potongan']);
    return model;
  }

  @override
  String get modelValue => "$code - $name";
}
