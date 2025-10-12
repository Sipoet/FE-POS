import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class ColumnAuthorize extends Model {
  String table;
  List<String> column;

  ColumnAuthorize({required this.table, required this.column, super.id});

  @override
  Map<String, dynamic> toMap() => {
        'table': table,
        'column': column.join(','),
      };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    table = attributes['table'];
    column = attributes['column'].map<String>((e) => e.toString()).toList();
  }

  @override
  String get modelValue => '$table ${column.join(',')}';

  @override
  String get modelName => 'column_authorize';
}

class ColumnAuthorizeClass extends ModelClass<ColumnAuthorize> {
  @override
  ColumnAuthorize initModel() => ColumnAuthorize(table: '', column: []);
}
