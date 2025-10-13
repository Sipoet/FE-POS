import 'package:fe_pos/model/transfer_item.dart';
export 'package:fe_pos/model/transfer_item.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Transfer extends Model {
  String code;
  String userName;
  List<TransferItem> transferItems;
  DateTime datetime;
  String description;
  double totalItem;
  String sourceLocation;
  String destLocation;
  String? shift;
  Transfer(
      {this.userName = '',
      this.description = '',
      this.totalItem = 0,
      this.code = '',
      this.sourceLocation = '',
      this.destLocation = '',
      this.shift = '',
      super.id,
      super.createdAt,
      super.updatedAt,
      DateTime? datetime,
      List<TransferItem>? transferItems})
      : transferItems = transferItems ?? <TransferItem>[],
        datetime = datetime ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() => {
        'user1': userName,
        'tanggal': datetime,
        'keterangan': description,
        'totalitem': totalItem,
        'updated_at': updatedAt,
        'shiftkerja': shift,
        'notransaksi': code,
        'kantordari': sourceLocation,
        'kantortujuan': destLocation
      };

  @override
  String get modelName => 'transfer';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      transferItems = TransferItemClass().findRelationsData(
        included: included,
        relation: json['relationships']['transfer_items'],
      );
    }
    userName = attributes['user1'];
    datetime = DateTime.parse(attributes['tanggal']);
    description = attributes['keterangan'];
    totalItem = double.parse(attributes['totalitem']);

    code = attributes['notransaksi'];
    shift = attributes['shiftkerja'];
    sourceLocation = attributes['kantordari'];
    destLocation = attributes['kantortujuan'];
  }

  @override
  String get modelValue => code;
}

class TransferClass extends ModelClass<Transfer> {
  @override
  Transfer initModel() => Transfer();
}
