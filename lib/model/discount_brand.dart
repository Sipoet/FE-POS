import 'package:fe_pos/model/brand.dart';
export 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/model.dart';

class DiscountBrand extends Model {
  Brand? brand;

  bool isExclude;
  DiscountBrand({super.id, this.brand, this.isExclude = false});

  @override
  factory DiscountBrand.fromJson(Map<String, dynamic> json,
      {List included = const []}) {
    var attributes = json['attributes'];
    return DiscountBrand(
      id: int.parse(json['id']),
      isExclude: attributes['is_exclude'],
      brand: Model.findRelationData<Brand>(
          included: included,
          relation: json['relationships']['brand'],
          convert: Brand.fromJson),
    );
  }

  String? get brandName => brand?.name;

  @override
  Map<String, dynamic> toMap() => {
        'brand_name': brandName,
        'brand.merek': brandName,
        'is_exclude': isExclude
      };
}
