import 'package:fe_pos/model/model.dart';

class Account extends Model {
  String code;
  String name;
  String? parentCode;
  bool cashBank;
  String? currency;
  Account(
      {super.id,
      this.parentCode,
      super.updatedAt,
      this.cashBank = false,
      this.currency = '',
      this.code = '',
      this.name = ''});

  @override
  factory Account.fromJson(Map<String, dynamic> json,
      {List included = const [], Account? model}) {
    final attributes = json['attributes'];

    model ??= Account();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.code = attributes['code'];
    model.name = attributes['name'];
    model.parentCode = attributes['parentacc'];
    model.currency = attributes['matauang'];
    model.cashBank = attributes['kasbank'] ?? false;
    return model;
  }
  @override
  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'parentacc': parentCode,
        'updated_at': updatedAt,
        'matauang': currency,
        'kasbank': cashBank
      };

  @override
  String get modelValue => '$code - $name';
}
