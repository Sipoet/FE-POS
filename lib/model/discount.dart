import 'package:fe_pos/model/customer_group.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/discount_item.dart';
export 'package:fe_pos/model/discount_item.dart';
import 'package:fe_pos/model/discount_supplier.dart';
export 'package:fe_pos/model/discount_supplier.dart';
import 'package:fe_pos/model/discount_brand.dart';
export 'package:fe_pos/model/discount_brand.dart';
import 'package:fe_pos/model/discount_item_type.dart';
export 'package:fe_pos/model/discount_item_type.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum DiscountCalculationType implements EnumTranslation {
  percentage,
  specialPrice,
  nominal;

  @override
  String toString() {
    if (this == percentage) {
      return 'percentage';
    } else if (this == nominal) {
      return 'nominal';
    } else if (this == specialPrice) {
      return 'special_price';
    }

    return '';
  }

  factory DiscountCalculationType.fromString(String value) {
    if (value == 'percentage') {
      return percentage;
    } else if (value == 'nominal') {
      return nominal;
    } else if (value == 'special_price') {
      return specialPrice;
    }
    throw '$value is not valid discount calculation type';
  }

  @override
  String humanize() {
    if (this == percentage) {
      return 'persentase';
    } else if (this == nominal) {
      return 'nominal';
    } else if (this == specialPrice) {
      return 'Special Price';
    }
    return '';
  }
}

enum DiscountType implements EnumTranslation {
  period,
  // repeatedHourOnPeriod,
  dayOfWeek;

  @override
  String toString() {
    if (this == period) {
      return 'period';
    } else if (this == dayOfWeek) {
      return 'day_of_week';
    }
    // else if (this == repeatedHourOnPeriod) {
    //   return 'repeated_hour_on_period';
    // }
    return '';
  }

  factory DiscountType.fromString(String value) {
    if (value == 'period') {
      return period;
    } else if (value == 'day_of_week') {
      return dayOfWeek;
    }
    // else if (value == 'repeated_hour_on_period') {
    //   return repeatedHourOnPeriod;
    // }
    throw '$value is not valid discount type';
  }

  @override
  String humanize() {
    if (this == period) {
      return 'Periode';
    } else if (this == dayOfWeek) {
      return 'Minggu';
    }
    // else if (this == repeatedHourOnPeriod) {
    //   return 'Jam Tertentu';
    // }
    return '';
  }
}

class Discount extends Model {
  String? itemCode;
  String? itemType;
  String? brandName;
  String? supplierCode;
  String? blacklistItemType;
  String? blacklistBrandName;
  String? blacklistSupplierCode;
  String? blacklistItemCode;
  dynamic discount1;
  Percentage? discount2;
  Percentage? discount3;
  Percentage? discount4;
  DateTime startTime;
  DateTime endTime;
  DiscountCalculationType calculationType;
  CustomerGroup? customerGroup;
  List<DiscountItem> discountItems = [];
  List<DiscountBrand> discountBrands = [];
  List<DiscountItemType> discountItemTypes = [];
  List<DiscountSupplier> discountSuppliers = [];

  String code;
  int weight;
  bool week1;
  bool week2;
  bool week3;
  bool week4;
  bool week5;
  bool week6;
  bool week7;
  DiscountType discountType;
  Discount(
      {super.id,
      this.code = '',
      this.itemCode,
      this.itemType,
      this.brandName,
      this.blacklistBrandName,
      this.blacklistItemType,
      this.blacklistSupplierCode,
      this.blacklistItemCode,
      this.supplierCode,
      this.customerGroup,
      required this.calculationType,
      required this.discount1,
      this.discount2,
      this.discount3,
      this.discount4,
      super.createdAt,
      super.updatedAt,
      this.week1 = false,
      this.week2 = false,
      this.week3 = false,
      this.week4 = false,
      this.week5 = false,
      this.week6 = false,
      this.week7 = false,
      this.discountType = DiscountType.period,
      required this.startTime,
      required this.endTime,
      this.weight = 1});

  @override
  String get modelName => 'discount';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    code = attributes['code']?.trim();
    itemCode = attributes['item_code'];
    itemType = attributes['item_type_name'];
    supplierCode = attributes['supplier_code'];
    brandName = attributes['brand_name'];

    calculationType = DiscountCalculationType.fromString(
        attributes['calculation_type'].toString());
    discountType =
        DiscountType.fromString(attributes['discount_type'].toString());
    blacklistItemType = attributes['blacklist_item_type_name'];
    blacklistSupplierCode = attributes['blacklist_supplier_code'];
    blacklistItemCode = attributes['blacklist_item_code'];
    blacklistBrandName = attributes['blacklist_brand_name'];
    discount1 = calculationType == DiscountCalculationType.percentage
        ? Percentage(attributes['discount1'] ?? 0)
        : Money(attributes['discount1'] * 100);
    discount2 = Percentage(attributes['discount2'] ?? 0);
    discount3 = Percentage(attributes['discount3'] ?? 0);
    discount4 = Percentage(attributes['discount4'] ?? 0);
    week1 = attributes['week1'];
    week2 = attributes['week2'];
    week3 = attributes['week3'];
    week4 = attributes['week4'];
    week5 = attributes['week5'];
    week6 = attributes['week6'];
    week7 = attributes['week7'];
    final relationships = json['relationships'];
    discountItems = DiscountItemClass().findRelationsData(
      included: included,
      relation: relationships['discount_items'],
    );

    discountSuppliers = DiscountSupplierClass().findRelationsData(
      included: included,
      relation: relationships['discount_suppliers'],
    );

    discountBrands = DiscountBrandClass().findRelationsData(
      included: included,
      relation: relationships['discount_brands'],
    );

    discountItemTypes = DiscountItemTypeClass().findRelationsData(
      included: included,
      relation: relationships['discount_item_types'],
    );

    customerGroup = CustomerGroupClass().findRelationData(
      included: included,
      relation: relationships['customer_group'],
    );
    weight = attributes['weight'];
    startTime = DateTime.parse(attributes['start_time']);
    endTime = DateTime.parse(attributes['end_time']);
  }

  String? get customerGroupCode => customerGroup?.code;

  List<Brand> get brands => discountBrands
      .where((element) => element.isExclude == false && element.brand != null)
      .map<Brand>((e) => e.brand as Brand)
      .toList();
  List<Brand> get blacklistBrands => discountBrands
      .where((element) => element.isExclude == true && element.brand != null)
      .map<Brand>((e) => e.brand as Brand)
      .toList();

  List<Item> get items => discountItems
      .where((element) => element.isExclude == false && element.item != null)
      .map<Item>((e) => e.item as Item)
      .toList();
  List<Item> get blacklistItems => discountItems
      .where((element) => element.isExclude == true && element.item != null)
      .map<Item>((e) => e.item as Item)
      .toList();

  List<Supplier> get suppliers => discountSuppliers
      .where(
          (element) => element.isExclude == false && element.supplier != null)
      .map<Supplier>((e) => e.supplier as Supplier)
      .toList();
  List<Supplier> get blacklistSuppliers => discountSuppliers
      .where((element) => element.isExclude == true && element.supplier != null)
      .map<Supplier>((e) => e.supplier as Supplier)
      .toList();

  List<ItemType> get itemTypes => discountItemTypes
      .where(
          (element) => element.isExclude == false && element.itemType != null)
      .map<ItemType>((e) => e.itemType as ItemType)
      .toList();
  List<ItemType> get blacklistItemTypes => discountItemTypes
      .where((element) => element.isExclude == true && element.itemType != null)
      .map<ItemType>((e) => e.itemType as ItemType)
      .toList();

  set brands(List<Brand> newBrands) {
    discountBrands.removeWhere((element) => !element.isExclude);
    for (final newBrand in newBrands) {
      discountBrands.add(DiscountBrand(brand: newBrand));
    }
  }

  set blacklistBrands(List<Brand> newBrands) {
    discountBrands.removeWhere((element) => element.isExclude);
    for (final newBrand in newBrands) {
      discountBrands.add(DiscountBrand(brand: newBrand, isExclude: true));
    }
  }

  set itemTypes(List<ItemType> newItemTypes) {
    discountItemTypes.removeWhere((element) => !element.isExclude);
    for (final newItemType in newItemTypes) {
      discountItemTypes.add(DiscountItemType(itemType: newItemType));
    }
  }

  set blacklistItemTypes(List<ItemType> newItemTypes) {
    discountItemTypes.removeWhere((element) => element.isExclude);
    for (final newItemType in newItemTypes) {
      discountItemTypes
          .add(DiscountItemType(itemType: newItemType, isExclude: true));
    }
  }

  set suppliers(List<Supplier> newSuppliers) {
    discountSuppliers.removeWhere((element) => !element.isExclude);
    for (final newSupplier in newSuppliers) {
      discountSuppliers.add(DiscountSupplier(supplier: newSupplier));
    }
  }

  set blacklistSuppliers(List<Supplier> newSuppliers) {
    discountSuppliers.removeWhere((element) => element.isExclude);
    for (final newSupplier in newSuppliers) {
      discountSuppliers
          .add(DiscountSupplier(supplier: newSupplier, isExclude: true));
    }
  }

  set items(List<Item> newItems) {
    discountItems.removeWhere((element) => !element.isExclude);
    for (final newItem in newItems) {
      discountItems.add(DiscountItem(item: newItem));
    }
  }

  set blacklistItems(List<Item> newItems) {
    discountItems.removeWhere((element) => element.isExclude);
    for (final newItem in newItems) {
      discountItems.add(DiscountItem(item: newItem, isExclude: true));
    }
  }

  @override
  Map<String, dynamic> toMap() => {
        'code': code.trim(),
        'item_code': itemCode,
        'item_type_name': itemType,
        'brand_name': brandName,
        'supplier_code': supplierCode,
        'item.kodeitem': itemCode,
        'item_type.jenis': itemType,
        'brand.merek': brandName,
        'supplier.kode': supplierCode,
        'calculation_type': calculationType,
        'discount_type': discountType,
        'blacklist_item_type.jenis': blacklistItemType,
        'blacklist_brand.merek': blacklistBrandName,
        'blacklist_supplier.kode': blacklistSupplierCode,
        'blacklist_item_type_name': blacklistItemType,
        'blacklist_brand_name': blacklistBrandName,
        'blacklist_supplier_code': blacklistSupplierCode,
        'blacklist_item_code': blacklistItemCode,
        'customer_group_code': customerGroup?.code,
        'discount1': discount1,
        'discount2': discount2,
        'discount3': discount3,
        'discount4': discount4,
        'week1': week1,
        'week2': week2,
        'week3': week3,
        'week4': week4,
        'week5': week5,
        'week6': week6,
        'week7': week7,
        'start_time': startTime,
        'end_time': endTime,
        'weight': weight,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Percentage get discount1Percentage => discount1 is Money
      ? Percentage(discount1.value / 100)
      : discount1 ?? const Percentage(0);
  Money get discount1Nominal => discount1 is Percentage
      ? Money(discount1.value * 100)
      : discount1 ?? const Money(0);
  double? get discount2Nominal => discount2?.value;
  double? get discount3Nominal => discount3?.value;
  double? get discount4Nominal => discount4?.value;

  @override
  String get modelValue => code;
}

class DiscountClass extends ModelClass<Discount> {
  @override
  Discount initModel() => Discount(
      calculationType: DiscountCalculationType.percentage,
      discount1: 0,
      startTime: DateTime.now(),
      endTime: DateTime.now());
}
