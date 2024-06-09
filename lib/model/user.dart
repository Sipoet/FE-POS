import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/role.dart';
export 'package:fe_pos/model/role.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum UserStatus {
  inactive,
  active;

  @override
  String toString() {
    if (this == active) {
      return 'active';
    } else if (this == inactive) {
      return 'inactive';
    }
    return '';
  }

  factory UserStatus.convertFromString(String? value) {
    if (value == 'active') {
      return active;
    } else if (value == 'inactive') {
      return inactive;
    }
    throw '$value is not valid employee status';
  }

  String humanize() {
    if (this == active) {
      return 'Aktif';
    } else if (this == inactive) {
      return 'Tidak Aktif';
    }
    return '';
  }
}

class User extends Model {
  String username;
  String? email;
  String? password;
  String? passwordConfirmation;
  UserStatus status;
  Role role;
  User(
      {required this.username,
      this.email,
      super.id,
      required this.role,
      this.status = UserStatus.inactive});

  @override
  Map<String, dynamic> toMap() => {
        'username': username,
        'email': email,
        'role_id': role.id,
        'role.name': role.name,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'status': status
      };

  @override
  factory User.fromJson(Map<String, dynamic> json,
      {User? model, List included = const []}) {
    var attributes = json['attributes'];
    Role? role = Model.findRelationData<Role>(
        included: included,
        relation: json['relationships']['role'],
        convert: Role.fromJson);

    model ??= User(username: '', role: Role(name: ''));
    model.id = int.parse(json['id']);
    model.username = attributes['username'];
    model.email = attributes['email'];
    model.status =
        UserStatus.convertFromString(attributes['status']?.toString());
    model.role = role ?? model.role;
    return model;
  }
}
