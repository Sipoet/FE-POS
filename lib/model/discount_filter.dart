import 'package:fe_pos/model/model.dart';

class DiscountFilter extends Model {
  String filterKey;
  String value;

  bool isExclude;
  DiscountFilter({
    super.id,
    this.value = '',
    this.filterKey = '',
    this.isExclude = false,
  });

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    isExclude = attributes['is_exclude'] ?? false;
    filterKey = attributes['filter_key'] ?? '';
    value = attributes['value'] ?? '';
  }

  @override
  Map<String, dynamic> toMap() => {
    'filter_key': filterKey,
    'value': value,
    'is_exclude': isExclude,
  };

  @override
  String get modelValue => value;
}

class DiscountFilterClass extends ModelClass<DiscountFilter> {
  @override
  DiscountFilter initModel() => DiscountFilter();
}
