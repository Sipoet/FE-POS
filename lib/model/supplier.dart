import 'package:fe_pos/model/model.dart';

class Supplier extends Model {
  String code;
  String name;
  String? bank;
  String? account;
  String? email;
  String? accountRegisterName;
  String? address;
  String? city;
  String? description;
  String? contact;
  Supplier({
    this.code = '',
    this.name = '',
    this.contact,
    this.email,
    super.id,
    this.bank,
    this.account,
    this.accountRegisterName,
    this.address,
    this.city,
    this.description,
  });

  @override
  String get modelName => 'supplier';

  @override
  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'bank': bank,
        'account': account,
        'account_register_name': accountRegisterName,
        'address': address,
        'contact': contact,
        'city': city,
        'description': description,
      };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    code = attributes['code'];
    name = attributes['name'];
    bank = attributes['bank'];
    account = attributes['account'];
    accountRegisterName = attributes['account_register_name'];
    address = attributes['address'];
    contact = attributes['contact'];
    email = attributes['email'];
    city = attributes['city'];
    description = attributes['description'];
  }

  @override
  String get modelValue => id.toString();
}

class SupplierClass extends ModelClass<Supplier> with FindModel<Supplier> {
  @override
  Supplier initModel() => Supplier();
}
