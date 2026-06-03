import 'package:fe_pos/model/forwarder.dart';
import 'package:fe_pos/model/location.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/purchase_shipment_detail.dart';
export 'package:fe_pos/model/purchase_shipment_detail.dart';

class PurchaseShipment extends Model with SaveNDestroyModel {
  List<PurchaseShipmentDetail> purchaseShipmentDetails = [];
  Location? location;
  DateTime? shippedAt;
  DateTime? arrivedAt;
  String? code;
  String? description;
  Money grandtotal;
  Forwarder? sender;
  String? receiver;
  PurchaseShipment({
    this.location,
    this.shippedAt,
    this.arrivedAt,
    this.code,
    this.grandtotal = const Money(0),
    this.sender,
    this.receiver,
    super.id,
    super.createdAt,
    super.updatedAt,
    List<PurchaseShipmentDetail>? purchaseShipmentDetails,
  }) : purchaseShipmentDetails = purchaseShipmentDetails ?? [];
  @override
  Map<String, dynamic> toMap() => {
    'shipped_at': shippedAt,
    'arrived_at': arrivedAt,
    'code': code,
    'sender': sender,
    'sender_id': sender?.id,
    'receiver': receiver,
    'location': location,
    'location_id': location?.id,
    'grandtotal': grandtotal,
    'description': description,
    'purchase_shipment_details_attributes': purchaseShipmentDetails
        .map((e) => e.asJson())
        .toList(),
  };

  @override
  void setFromJson(
    Map<String, dynamic> json, {
    List<dynamic> included = const [],
  }) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    if (included.isNotEmpty) {
      purchaseShipmentDetails = PurchaseShipmentDetailClass().findRelationsData(
        included: included,
        relation: json['relationships']?['purchase_shipment_details'],
      );
      location = LocationClass().findRelationData(
        included: included,
        relation: json['relationships']?['location'],
      );
      sender = ForwarderClass().findRelationData(
        included: included,
        relation: json['relationships']?['sender'],
      );
    }
    code = attributes['code'];
    receiver = attributes['receiver'];
    shippedAt = DateTime.tryParse(attributes['shipped_at'] ?? '');
    arrivedAt = DateTime.tryParse(attributes['arrived_at'] ?? '');
    description = attributes['description'];
    grandtotal = Money.tryParse(attributes['grandtotal']) ?? const Money(0);
  }
}

class PurchaseShipmentClass extends ModelClass<PurchaseShipment> {
  @override
  PurchaseShipment initModel() => PurchaseShipment();
}
