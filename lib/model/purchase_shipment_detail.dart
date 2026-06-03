import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/purchase_invoice.dart';
import 'package:fe_pos/model/purchase_shipment.dart';
import 'package:fe_pos/model/cost_detail.dart';

class PurchaseShipmentDetail extends Model with SaveNDestroyModel {
  PurchaseInvoice? purchaseInvoice;
  PurchaseShipment? purchaseShipment;
  CostDetail? costDetail;
  Money shippingCost;
  int sackQuantity;
  String? description;

  PurchaseShipmentDetail({
    this.purchaseInvoice,
    this.purchaseShipment,
    this.costDetail,
    this.description,
    this.shippingCost = const Money(0),
    this.sackQuantity = 0,
  });

  @override
  Map<String, dynamic> toMap() => {
    'cost_detail': costDetail,
    'cost_detail_id': costDetail?.id,
    'purchase_shipment': purchaseShipment,
    'purchase_shipment_id': purchaseShipment?.id,
    'purchase_invoice': purchaseInvoice,
    'purchase_invoice_id': purchaseInvoice?.id,
    'shipping_cost': shippingCost,
    'sack_quantity': sackQuantity,
    'description': description,
  };
  @override
  void setFromJson(
    Map<String, dynamic> json, {
    List<dynamic> included = const [],
  }) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    shippingCost =
        Money.tryParse(attributes['shipping_cost']) ?? const Money(0);
    sackQuantity = int.tryParse(attributes['sack_quantity'].toString()) ?? 0;
    description = attributes['description'];
    if (included.isNotEmpty) {
      purchaseShipment = PurchaseShipmentClass().findRelationData(
        included: included,
        relation: json['relationships']?['purchase_shipment'],
        isRootIncluded: false,
      );
      purchaseInvoice = PurchaseInvoiceClass().findRelationData(
        included: included,
        relation: json['relationships']?['purchase_invoice'],
      );
      costDetail = CostDetailClass().findRelationData(
        included: included,
        relation: json['relationships']?['cost_detail'],
      );
    }
  }
}

class PurchaseShipmentDetailClass extends ModelClass<PurchaseShipmentDetail> {
  @override
  PurchaseShipmentDetail initModel() => PurchaseShipmentDetail();
}
