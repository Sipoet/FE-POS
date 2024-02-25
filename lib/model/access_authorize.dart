import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class AccessAuthorize extends Model {
  String controller;
  List<String> action;
  int? id;
  AccessAuthorize({required this.controller, required this.action, this.id});

  @override
  Map<String, dynamic> toMap() => {
        'controller': controller,
        'action': action.join(','),
      };

  @override
  factory AccessAuthorize.fromJson(Map<String, dynamic> json,
      {AccessAuthorize? model}) {
    var attributes = json['attributes'];
    model ??= AccessAuthorize(controller: '', action: []);
    model.id = int.parse(json['id']);
    model.controller = attributes['controller'];
    model.action =
        attributes['action'].map<String>((e) => e.toString()).toList();
    return model;
  }
}
