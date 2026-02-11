import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class ColumnAuthorize extends Model {
  String table;
  List<String> columns;

  ColumnAuthorize({required this.table, required this.columns, super.id});

  @override
  Map<String, dynamic> toMap() => {'table': table, 'column': columns.join(',')};

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    table = attributes['table'];
    columns = attributes['column'].map<String>((e) => e.toString()).toList();
  }

  @override
  String get modelValue => '$table ${columns.join(',')}';

  @override
  String get modelName => 'column_authorize';
}

class ColumnAuthorizeClass extends ModelClass<ColumnAuthorize> {
  @override
  ColumnAuthorize initModel() => ColumnAuthorize(table: '', columns: []);
}
