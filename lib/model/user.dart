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
      {this.username = '',
      this.email,
      super.id,
      Role? role,
      this.status = UserStatus.inactive})
      : role = role ?? Role();

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {
      'username': username,
      'email': email,
      'role_id': role.id,
      'role.name': role.name,
      'status': status
    };
    if (password != null && password!.isNotEmpty) {
      result['password'] = password;
      result['password_confirmation'] = passwordConfirmation;
    }
    return result;
  }

  @override
  String get modelName => 'user';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    Role? role = RoleClass().findRelationData(
      included: included,
      relation: json['relationships']['role'],
    );

    username = attributes['username'] ?? '';
    email = attributes['email'];
    // model.status =
    //     UserStatus.convertFromString(attributes['status']?.toString());
    role = role ?? role;
  }

  @override
  String get modelValue => username;
}

class UserClass extends ModelClass<User> {
  @override
  User initModel() => User();
}
