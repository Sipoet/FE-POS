import 'package:fe_pos/model/model.dart';

class Customer extends Model {
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
  Customer({
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
        'kode': code,
        'nama': name,
        'bank': bank,
        'norek': account,
        'atasnama': accountRegisterName,
        'alamat': address,
        'kontak': contact,
        'kota': city,
        'keterangan': description,
      };

  @override
  String get modelName => 'customer';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);

    code = attributes['kode'];
    name = attributes['nama'];
    bank = attributes['bank'];
    account = attributes['norek'];
    accountRegisterName = attributes['atasnama'];
    address = attributes['alamat'];
    contact = attributes['kontak'];
    email = attributes['email'];
    city = attributes['kota'];
    description = attributes['keterangan'];
  }

  @override
  String get modelValue => "$code - $name";
}

class CustomerClass extends ModelClass<Customer> {
  @override
  Customer initModel() => Customer();
}
