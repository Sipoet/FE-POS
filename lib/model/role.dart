import 'package:fe_pos/model/access_authorize.dart';
import 'package:fe_pos/model/column_authorize.dart';
export 'package:fe_pos/model/access_authorize.dart';
export 'package:fe_pos/model/column_authorize.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Role extends Model {
  String name;
  int? id;
  List<ColumnAuthorize> columnAuthorizes;
  List<AccessAuthorize> accessAuthorizes;
  Role(
      {required this.name,
      this.id,
      this.columnAuthorizes = const <ColumnAuthorize>[],
      this.accessAuthorizes = const <AccessAuthorize>[]});

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
      };

  @override
  factory Role.fromJson(Map<String, dynamic> json,
      {Role? model, List included = const []}) {
    var attributes = json['attributes'];
    List<AccessAuthorize> accessAuthorizes = [];
    List<ColumnAuthorize> columnAuthorizes = [];
    if (included.isNotEmpty) {
      final accessRelated =
          json['relationships']['access_authorizes']?['data'] ?? [];
      final columnRelated =
          json['relationships']['column_authorizes']?['data'] ?? [];

      accessAuthorizes = accessRelated.map<AccessAuthorize>((data) {
        final accessData = included.firstWhere(
            (row) => row['type'] == data['type'] && row['id'] == data['id']);

        return AccessAuthorize.fromJson(accessData);
      }).toList();

      columnAuthorizes = columnRelated.map<ColumnAuthorize>((data) {
        final columnData = included.firstWhere(
            (row) => row['type'] == data['type'] && row['id'] == data['id']);

        return ColumnAuthorize.fromJson(columnData);
      }).toList();
    }
    model ??= Role(name: '');
    model.id = int.parse(json['id']);
    model.name = attributes['name'];
    model.columnAuthorizes = columnAuthorizes;
    model.accessAuthorizes = accessAuthorizes;
    return model;
  }
}
