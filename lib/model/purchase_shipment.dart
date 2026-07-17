import 'package:fe_pos/model/forwarder.dart';
import 'package:fe_pos/model/location.dart';
import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/model/employee.dart';
export 'package:fe_pos/tool/purchase_calculator.dart';
import 'package:fe_pos/model/purchase_shipment_detail.dart';
export 'package:fe_pos/model/purchase_shipment_detail.dart';

enum PurchaseShipmentStatus implements EnumTranslation {
  draft,
  confirmed,
  delivered;

  @override
  String humanize() {
    switch (this) {
      case draft:
        return 'draft';
      case confirmed:
        return 'confirmed';
      case delivered:
        return 'Terkirim';
    }
  }

  @override
  String toString() {
    switch (this) {
      case draft:
        return 'draft';
      case confirmed:
        return 'confirmed';
      case delivered:
        return 'delivered';
    }
  }

  static PurchaseShipmentStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return draft;
      case 'confirmed':
        return confirmed;
      case 'delivered':
        return delivered;
      default:
        throw 'unknow status of $value';
    }
  }
}

class PurchaseShipment extends Model with SaveNDestroyModel {
  List<PurchaseShipmentDetail> purchaseShipmentDetails = [];
  Location? location;
  DateTime? shippedAt;
  DateTime? arrivedAt;
  String? code;
  String? description;
  Money grandtotal;
  Forwarder? sender;
  Employee? receiver;
  PurchaseShipmentStatus? status;
  PurchaseShipment({
    this.location,
    this.shippedAt,
    this.arrivedAt,
    this.code,
    this.grandtotal = const Money(0),
    this.sender,
    this.receiver,
    super.id,
    this.status,
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
    'status': status,
    'sender_id': sender?.id,
    'receiver': receiver,
    'receiver_id': receiver?.id,
    'location': location,
    'location_id': location?.id,
    'grandtotal': grandtotal,
    'description': description,
    'purchase_shipment_details_attributes': purchaseShipmentDetails,
  };
  @override
  String get path => 'purchase_shipments';

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
      receiver = EmployeeClass().findRelationData(
        included: included,
        relation: json['relationships']?['receiver'],
      );
    }
    code = attributes['code'];
    shippedAt = DateTime.tryParse(attributes['shipped_at'] ?? '');
    arrivedAt = DateTime.tryParse(attributes['arrived_at'] ?? '');
    description = attributes['description'];
    grandtotal = Money.tryParse(attributes['grandtotal']) ?? const Money(0);
    try {
      status = PurchaseShipmentStatus.fromString(attributes['status']);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

class PurchaseShipmentClass extends ModelClass<PurchaseShipment> {
  @override
  PurchaseShipment initModel() => PurchaseShipment();
}
