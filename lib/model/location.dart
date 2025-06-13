import 'package:fe_pos/model/model.dart';

class Location extends Model {
  String code;
  String name;
  bool? branch;
  String? accountCode;
  Location(
      {super.id,
      this.accountCode,
      this.branch,
      this.code = '',
      this.name = ''});

  @override
  factory Location.fromJson(Map<String, dynamic> json,
      {List included = const [], Location? model}) {
    final attributes = json['attributes'];

    model ??= Location();
    model.id = json['id'];
    model.code = attributes['code'];
    model.name = attributes['name'];
    model.branch = attributes['cabang'];
    model.accountCode = attributes['kodeacc'];
    return model;
  }
  @override
  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'cabang': branch,
        'kodeacc': accountCode,
      };

  @override
  String get modelValue => '$code - $name';
}
