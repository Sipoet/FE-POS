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
  factory PaymentProviderEdc.fromJson(Map<String, dynamic> json,
      {PaymentProviderEdc? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= PaymentProviderEdc();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.terminalId = attributes['terminal_id'] ?? '';
    model.merchantId = attributes['merchant_id'] ?? '';
    return model;
  }
}
