import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class AccessAuthorize extends Model {
  String controller;
  List<String> action;
  AccessAuthorize({required this.controller, required this.action, super.id});

  @override
  Map<String, dynamic> toMap() => {
        'controller': controller,
        'action': action.join(','),
      };

  @override
  String get modelName => 'access_authorize';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    controller = attributes['controller'];
    action = attributes['action'].map<String>((e) => e.toString()).toList();
  }

  @override
  String get modelValue => '$controller - ${action.join(',')}';
}

class AccessAuthorizeClass extends ModelClass<AccessAuthorize> {
  @override
  AccessAuthorize initModel() => AccessAuthorize(controller: '', action: []);
}
