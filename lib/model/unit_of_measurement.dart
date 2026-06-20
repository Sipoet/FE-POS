import 'package:fe_pos/model/model.dart';

class UnitOfMeasurement extends Model {
  String? name;
  String? groupName;
  double groupConversion;
  UnitOfMeasurement({this.name, this.groupName, this.groupConversion = 0});
  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'group_name': groupName,
    'group_conversion': groupConversion,
  };
  @override
  String get modelValue => name ?? '';
  @override
  String get path => 'unit_of_measurements';
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'] ?? {};
    super.setFromJson(json, included: included);
    name = attributes['name'];
    groupName = attributes['group_name'];
    groupConversion =
        double.tryParse(attributes['group_conversion'] ?? '') ?? 0;
  }
}

class UnitOfMeasurementClass extends ModelClass<UnitOfMeasurement> {
  @override
  UnitOfMeasurement initModel() => UnitOfMeasurement();
}
