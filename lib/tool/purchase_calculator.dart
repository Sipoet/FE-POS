import 'package:fe_pos/model/cost_detail.dart';
import 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/discount_detail_calculator.dart';

class PurchaseCalculator {
  PurchaseCalculator();

  PurchaseCalculatorResult headerCalculate({
    required List<PurchaseDetailCalculatorResult> details,
    List<DiscountDetail>? discountDetails,
    required List<CostDetail> costDetails,
    required TaxType taxType,
    Percentage? taxValue,
  }) {
    final result = PurchaseCalculatorResult();
    result.subtotal = details.map<Money>((e) => e.total).sum;
    result.discountAmount = discountDetails == null
        ? const Money(0)
        : DiscountDetailCalculator(discountDetails).calculate(result.subtotal);
    result.discountTotal =
        details.map<Money>((e) => e.discountAmount).sum + result.discountAmount;
    result.costTotal = costDetails.map<Money>((e) => e.amount).sum;
    result.grandtotal =
        result.subtotal - result.discountAmount + result.costTotal;
    if (taxType == .excluded && taxValue != null) {
      result.taxAmount = (result.subtotal - result.discountAmount) * taxValue;
      result.grandtotal += result.taxAmount;
    }
    return result;
  }

  PurchaseDetailCalculatorResult detailCalculate({
    required double quantity,
    required Money price,
    List<DiscountDetail>? discountDetails,
  }) {
    final result = PurchaseDetailCalculatorResult();
    result.subtotal = price * quantity;
    result.discountAmount = discountDetails == null
        ? const Money(0)
        : DiscountDetailCalculator(discountDetails).calculate(result.subtotal);
    result.total = result.subtotal - result.discountAmount;
    return result;
  }
}

class PurchaseCalculatorResult {
  Money subtotal = Money(0);
  Money grandtotal = Money(0);
  Money discountAmount = Money(0);
  Money discountTotal = Money(0);
  Money costTotal = Money(0);
  Money taxAmount = Money(0);
  PurchaseCalculatorResult();
}

class PurchaseDetailCalculatorResult {
  Money subtotal = Money(0);
  Money total = Money(0);
  Money discountAmount = Money(0);

  PurchaseDetailCalculatorResult();
}

enum TaxType implements EnumTranslation {
  non,
  included,
  excluded;

  @override
  String toString() {
    switch (this) {
      case non:
        return 'non';
      case included:
        return 'included';
      case excluded:
        return 'excluded';
    }
  }

  @override
  String humanize() {
    switch (this) {
      case non:
        return 'non';
      case included:
        return 'included';
      case excluded:
        return 'excluded';
    }
  }

  static TaxType fromString(String value) {
    switch (value) {
      case 'non':
        return non;
      case 'included':
        return included;
      case 'excluded':
        return excluded;
      default:
        throw '$value invalid tax type';
    }
  }
}
