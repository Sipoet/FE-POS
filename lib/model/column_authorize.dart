import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class ColumnAuthorize extends Model {
  String table;
  List<String> column;
  int? id;
  ColumnAuthorize({required this.table, required this.column, this.id});

  @override
  Map<String, dynamic> toMap() => {
        'table': table,
        'column': column.join(','),
      };

  @override
  factory ColumnAuthorize.fromJson(Map<String, dynamic> json,
      {ColumnAuthorize? model}) {
    var attributes = json['attributes'];
    model ??= ColumnAuthorize(table: '', column: []);
    model.id = int.parse(json['id']);
    model.table = attributes['table'];
    model.column =
        attributes['column'].map<String>((e) => e.toString()).toList();
    return model;
  }
}