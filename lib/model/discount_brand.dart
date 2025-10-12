import 'package:fe_pos/model/brand.dart';
export 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/model.dart';

class DiscountBrand extends Model {
  Brand? brand;

  bool isExclude;
  DiscountBrand({super.id, this.brand, this.isExclude = false});

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    isExclude = attributes['is_exclude'];
    brand = BrandClass().findRelationData(
      included: included,
      relation: json['relationships']['brand'],
    );
  }

  String? get brandName => brand?.name;
  @override
  String get modelName => 'discount_brand';

  @override
  Map<String, dynamic> toMap() => {
        'brand_name': brandName,
        'brand.merek': brandName,
        'is_exclude': isExclude
      };

  @override
  String get modelValue => brand?.modelValue ?? '';
}

class DiscountBrandClass extends ModelClass<DiscountBrand> {
  @override
  DiscountBrand initModel() => DiscountBrand();
}
