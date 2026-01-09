import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/role.dart';
export 'package:fe_pos/model/role.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum UserStatus implements EnumTranslation {
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

  factory UserStatus.fromString(String? value) {
    if (value == 'active') {
      return active;
    } else if (value == 'inactive') {
      return inactive;
    }
    throw '$value is not valid employee status';
  }
  @override
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
  DateTime? currentSignInAt;
  DateTime? lastSignInAt;
  Role role;
  User({
    this.username = '',
    this.email,
    super.id,
    this.lastSignInAt,
    this.currentSignInAt,
    Role? role,
    this.status = UserStatus.inactive,
  }) : role = role ?? Role();

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {
      'username': username,
      'email': email,
      'role_id': role.id,
      'role.name': role.name,
      'role': role,
      'current_sign_in_at': currentSignInAt,
      'last_sign_in_at': lastSignInAt,
      'status': status,
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
    role =
        RoleClass().findRelationData(
          included: included,
          relation: json['relationships']['role'],
        ) ??
        role;

    username = attributes['username'] ?? '';
    email = attributes['email'];
    if (attributes['status'] != null) {
      status = UserStatus.fromString(attributes['status'].toString());
    }
  }

  @override
  String get modelValue => username;
}

class UserClass extends ModelClass<User> {
  @override
  User initModel() => User();
}
