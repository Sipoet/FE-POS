import 'package:fe_pos/model/model.dart';

export 'package:fe_pos/tool/custom_type.dart';

class HashModel extends Model {
  Map<String, dynamic> data;
  HashModel({this.data = const {}, super.id});

  @override
  Map<String, dynamic> toMap() => data;

  @override
  factory HashModel.fromJson(Map<String, dynamic> json,
      {HashModel? model, List included = const []}) {
    model ??= HashModel(data: json);
    model.id = json['id'];
    return model;
  }

  @override
  String get modelValue => '';
}
