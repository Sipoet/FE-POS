import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/role.dart';
export 'package:fe_pos/model/role.dart';
export 'package:fe_pos/tool/custom_type.dart';

class User extends Model {
  String username;
  String? email;
  String? password;
  String? passwordConfirmation;
  Role role;
  int? id;
  User({required this.username, this.email, this.id, required this.role});

  @override
  Map<String, dynamic> toMap() => {
        'username': username,
        'email': email,
        'role_id': role.id,
        'role.name': role.name,
        'password': password,
        'password_confirmation': passwordConfirmation
      };

  @override
  factory User.fromJson(Map<String, dynamic> json,
      {User? model, List included = const []}) {
    var attributes = json['attributes'];
    Role? role;
    final roleRelated = json['relationships']?['role']?['data'];
    if (included.isNotEmpty && roleRelated != null) {
      final roleData = included.firstWhere((row) =>
          row['type'] == roleRelated['type'] && row['id'] == roleRelated['id']);
      if (roleData != null) {
        role = Role.fromJson(roleData);
      }
    }
    model ??= User(username: '', role: Role(name: ''));
    model.id = int.parse(json['id']);
    model.username = attributes['username'];
    model.email = attributes['email'];
    model.role = role ?? model.role;
    return model;
  }
}