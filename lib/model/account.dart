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
  String get modelName => 'account';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    final attributes = json['attributes'];
    code = attributes['code'];
    name = attributes['name'];
    parentCode = attributes['parentacc'];
    currency = attributes['matauang'];
    cashBank = attributes['kasbank'] ?? false;
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

class AccountClass extends ModelClass<Account> {
  @override
  Account initModel() => Account();
}
