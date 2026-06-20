import 'package:fe_pos/model/model.dart';

export 'package:fe_pos/tool/custom_type.dart';

class HashModel extends Model {
  Map<String, dynamic>? data;
  HashModel({this.data, super.id});

  @override
  Map<String, dynamic> toMap() => data ?? {};

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    data = json;
  }

  @override
  String get path => 'models';
}

class HashModelClass extends ModelClass<HashModel> {
  @override
  HashModel initModel() => HashModel();
}
