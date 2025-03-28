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
  factory AccessAuthorize.fromJson(Map<String, dynamic> json,
      {AccessAuthorize? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= AccessAuthorize(controller: '', action: []);
    model.id = int.parse(json['id']);
    model.controller = attributes['controller'];
    model.action =
        attributes['action'].map<String>((e) => e.toString()).toList();
    return model;
  }

  @override
  String get modelValue => '$controller - ${action.join(',')}';
}
