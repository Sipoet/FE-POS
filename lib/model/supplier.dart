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
  String toString() {
    return name;
  }

  @override
  factory Supplier.fromJson(Map<String, dynamic> json,
      {Supplier? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= Supplier();
    model.id = json['id'];
    model.code = attributes['code'];
    model.name = attributes['name'];
    model.bank = attributes['bank'];
    model.account = attributes['account'];
    model.accountRegisterName = attributes['account_register_name'];
    model.address = attributes['address'];
    model.contact = attributes['contact'];
    model.email = attributes['email'];
    model.city = attributes['city'];
    model.description = attributes['description'];
    return model;
  }
}
