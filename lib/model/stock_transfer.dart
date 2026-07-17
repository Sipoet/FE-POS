export 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/location.dart';
import 'package:fe_pos/model/stock_transfer_detail.dart';
export 'package:fe_pos/model/stock_transfer_detail.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/purchase_order.dart';
export 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/tool/purchase_calculator.dart';

enum StockTransferStatus implements EnumTranslation {
  draft,
  confirmed;

  @override
  String humanize() {
    switch (this) {
      case draft:
        return 'draft';
      case confirmed:
        return 'confirmed';
    }
  }

  @override
  String toString() {
    switch (this) {
      case draft:
        return 'draft';
      case confirmed:
        return 'confirmed';
    }
  }

  static StockTransferStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return draft;
      case 'confirmed':
        return confirmed;
      default:
        throw 'unknow status of $value';
    }
  }
}

class StockTransfer extends Model with SaveNDestroyModel, Tagable {
  String code;
  Location? fromLocation;
  Location? toLocation;
  DateTime? transactionAt;
  String? description;
  List<StockTransferDetail> stockTransferDetails = [];
  StockTransferStatus? status;
  double? productTotal;
  StockTransfer({
    this.code = '',
    this.fromLocation,
    this.toLocation,
    this.description,
    this.status,
    this.productTotal,
    super.id,
    super.createdAt,
    super.updatedAt,
    List<StockTransferDetail>? stockTransferDetails,
    List<CostDetail>? costDetails,
  }) : stockTransferDetails = stockTransferDetails ?? <StockTransferDetail>[];

  @override
  String get path => 'stock_transfers';
  @override
  Map<String, dynamic> toMap() => {
    'code': code,
    'transaction_at': transactionAt,
    'status': status,
    'description': description,
    'from_location': fromLocation,
    'to_location': toLocation,
    'stock_transfer_details_attributes': stockTransferDetails,
  };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      stockTransferDetails = StockTransferDetailClass().findRelationsData(
        included: included,
        relation: json['relationships']['stock_transfer_details'],
      );
      fromLocation = LocationClass().findRelationData(
        included: included,
        relation: json['relationships']['from_location'],
      );
      toLocation = LocationClass().findRelationData(
        included: included,
        relation: json['relationships']['to_location'],
      );
    }
    id = json['id'];
    code = attributes['code'] ?? '';
    try {
      if (attributes['status'] != null) {
        status = StockTransferStatus.fromString(attributes['status']);
      }
    } catch (error) {
      debugPrint(error.toString());
    }

    description = attributes['description'];
  }

  @override
  String get modelValue => code;
}

class StockTransferClass extends ModelClass<StockTransfer> {
  @override
  StockTransfer initModel() => StockTransfer();
}
