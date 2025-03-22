import 'package:fe_pos/model/model.dart';

class Bank extends Model {
  String code;
  String name;
  Bank({super.id, this.code = '', this.name = ''});

  @override
  factory Bank.fromJson(Map<String, dynamic> json,
      {List included = const [], Bank? model}) {
    final attributes = json['attributes'];

    model ??= Bank();
    model.id = json['id'];
    model.code = attributes['kodebank'];
    model.name = attributes['namabank'];
    return model;
  }
  @override
  Map<String, dynamic> toMap() => {
        'kodebank': code,
        'namabank': name,
      };

  @override
  String get modelValue => '$code - $name';
}
