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
  factory Transfer.fromJson(Map<String, dynamic> json,
      {Transfer? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= Transfer(userName: '');
    if (included.isNotEmpty) {
      model.transferItems = Model.findRelationsData<TransferItem>(
          included: included,
          relation: json['relationships']['transfer_items'],
          convert: TransferItem.fromJson);
    }
    Model.fromModel(model, attributes);
    model.id = json['id'];
    model.userName = attributes['user1'];
    model.datetime = DateTime.parse(attributes['tanggal']);
    model.description = attributes['keterangan'];
    model.totalItem = double.parse(attributes['totalitem']);

    model.code = attributes['notransaksi'];
    model.shift = attributes['shiftkerja'];
    model.sourceLocation = attributes['kantordari'];
    model.destLocation = attributes['kantortujuan'];

    return model;
  }
}
