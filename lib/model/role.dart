import 'package:fe_pos/model/access_authorize.dart';
import 'package:fe_pos/model/column_authorize.dart';
export 'package:fe_pos/model/access_authorize.dart';
export 'package:fe_pos/model/column_authorize.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/role_work_schedule.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Role extends Model {
  String name;
  List<ColumnAuthorize> columnAuthorizes;
  List<AccessAuthorize> accessAuthorizes;
  List<RoleWorkSchedule> roleWorkSchedules;
  Role(
      {this.name = '',
      super.id,
      super.createdAt,
      super.updatedAt,
      List<RoleWorkSchedule>? roleWorkSchedules,
      List<ColumnAuthorize>? columnAuthorizes,
      List<AccessAuthorize>? accessAuthorizes})
      : roleWorkSchedules = roleWorkSchedules ?? <RoleWorkSchedule>[],
        columnAuthorizes = columnAuthorizes ?? <ColumnAuthorize>[],
        accessAuthorizes = accessAuthorizes ?? <AccessAuthorize>[];

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  String get modelName => 'role';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      accessAuthorizes = AccessAuthorizeClass().findRelationsData(
        included: included,
        relation: json['relationships']?['access_authorizes'],
      );
      columnAuthorizes = ColumnAuthorizeClass().findRelationsData(
        included: included,
        relation: json['relationships']?['column_authorizes'],
      );
      roleWorkSchedules = RoleWorkScheduleClass().findRelationsData(
        included: included,
        relation: json['relationships']?['role_work_schedules'],
      );
    }
    super.setFromJson(json, included: included);
    name = attributes['name'];
  }

  @override
  String get modelValue => name;
}

class RoleClass extends ModelClass<Role> {
  @override
  Role initModel() => Role();
}
