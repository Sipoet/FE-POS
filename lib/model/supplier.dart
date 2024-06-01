import 'package:fe_pos/model/model.dart';

class Supplier extends Model {
  String code;
  String name;
  Supplier({this.code = '', this.name = '', super.id});

  @override
  Map<String, dynamic> toMap() => {
        'kode': code,
        'nama': name,
      };

  @override
  factory Supplier.fromJson(Map<String, dynamic> json,
      {Supplier? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= Supplier();
    model.id = json['id'];
    model.code = attributes['kode'];
    model.name = attributes['nama'];
    return model;
  }
}
