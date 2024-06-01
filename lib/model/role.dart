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
      {required this.name,
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
      };

  @override
  factory Role.fromJson(Map<String, dynamic> json,
      {Role? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= Role(name: '');
    if (included.isNotEmpty) {
      model.accessAuthorizes = Model.findRelationsData<AccessAuthorize>(
          included: included,
          relation: json['relationships']['access_authorizes'],
          convert: AccessAuthorize.fromJson);
      model.columnAuthorizes = Model.findRelationsData<ColumnAuthorize>(
          included: included,
          relation: json['relationships']['column_authorizes'],
          convert: ColumnAuthorize.fromJson);
      model.roleWorkSchedules = Model.findRelationsData<RoleWorkSchedule>(
          included: included,
          relation: json['relationships']['role_work_schedules'],
          convert: RoleWorkSchedule.fromJson);
    }
    Model.fromModel(model, attributes);
    model.id = int.parse(json['id']);
    model.name = attributes['name'];
    return model;
  }
}
