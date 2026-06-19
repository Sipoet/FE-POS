import 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/tool/custom_type.dart';

class DiscountDetailCalculator {
  List<DiscountDetail> discountDetails;

  DiscountDetailCalculator(this.discountDetails);

  Money calculate(Money amount) {
    Money result = amount * 1;
    for (DiscountDetail discountDetail in discountDetails) {
      result -= _calculateBased(discountDetail: discountDetail, on: result);
    }
    return amount - result;
  }

  Money _calculateBased({
    required DiscountDetail discountDetail,
    required Money on,
  }) {
    switch (discountDetail.type) {
      case .percentage:
        return on * discountDetail.value;
      case .nominal:
        return Money(discountDetail.value);
    }
  }
}
