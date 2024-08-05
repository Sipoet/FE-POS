import 'package:fe_pos/model/model.dart';

class Supplier extends Model {
  String code;
  String name;
  String? bank;
  String? account;
  String? accountRegisterName;
  String? address;
  String? city;
  String? description;
  Supplier({
    this.code = '',
    this.name = '',
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
        'kota': city,
        'keterangan': description,
      };

  @override
  factory Supplier.fromJson(Map<String, dynamic> json,
      {Supplier? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= Supplier();
    model.id = json['id'];
    model.code = attributes['kode'];
    model.name = attributes['nama'];
    model.bank = attributes['bank'];
    model.account = attributes['norek'];
    model.accountRegisterName = attributes['atasnama'];
    model.address = attributes['alamat'];
    model.city = attributes['kota'];
    model.description = attributes['keterangan'];
    return model;
  }
}
