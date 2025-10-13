import 'package:fe_pos/model/model.dart';

class Bank extends Model {
  String code;
  String name;
  Bank({super.id, this.code = '', this.name = ''});

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    final attributes = json['attributes'];
    code = attributes['kodebank'];
    name = attributes['namabank'];
  }

  @override
  Map<String, dynamic> toMap() => {
        'kodebank': code,
        'namabank': name,
      };

  @override
  String get modelValue => '$code - $name';
}

class BankClass extends ModelClass<Bank> {
  @override
  Bank initModel() => Bank();
}
