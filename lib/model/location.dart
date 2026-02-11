import 'package:fe_pos/model/model.dart';

class Location extends Model {
  String code;
  String name;
  bool? branch;
  String? accountCode;
  Location({
    super.id,
    this.accountCode,
    this.branch,
    this.code = '',
    this.name = '',
  });

  @override
  String get path => 'ipos/locations';
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    final attributes = json['attributes'];
    code = attributes['code'];
    name = attributes['name'];
    branch = attributes['cabang'];
    accountCode = attributes['kodeacc'];
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

class LocationClass extends ModelClass<Location> {
  @override
  Location initModel() => Location();
}
