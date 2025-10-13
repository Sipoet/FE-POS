import 'package:fe_pos/model/model.dart';

class PaymentProviderEdc extends Model {
  String terminalId;
  String merchantId;
  PaymentProviderEdc(
      {this.terminalId = '',
      this.merchantId = '',
      super.id,
      super.createdAt,
      super.updatedAt});

  @override
  Map<String, dynamic> toMap() => {
        'terminal_id': terminalId,
        'merchant_id': merchantId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  String get modelName => 'payment_provider_edc';
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    terminalId = attributes['terminal_id'] ?? '';
    merchantId = attributes['merchant_id'] ?? '';
  }

  @override
  String get modelValue => "$terminalId - $merchantId";
}

class PaymentProviderEdcClass extends ModelClass<PaymentProviderEdc> {
  @override
  PaymentProviderEdc initModel() => PaymentProviderEdc();
}
