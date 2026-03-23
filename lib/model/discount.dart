import 'package:collection/collection.dart';
import 'package:fe_pos/model/customer_group.dart';
import 'package:fe_pos/model/model.dart';

import 'package:fe_pos/model/discount_filter.dart';
import 'package:fe_pos/model/item.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/model/item.dart';
export 'package:fe_pos/model/discount_filter.dart';

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
  String? itemTypeName;
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
  List<DiscountFilter> discountFilters = [];

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
  Discount({
    super.id,
    this.code = '',
    this.itemCode,
    this.itemTypeName,
    this.brandName,
    this.blacklistBrandName,
    this.blacklistItemType,
    this.blacklistSupplierCode,
    this.blacklistItemCode,
    this.supplierCode,
    this.customerGroup,
    List<DiscountFilter>? discountFilters,
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
    this.weight = 1,
  }) : discountFilters = discountFilters ?? [];

  @override
  String get modelName => 'discount';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    code = attributes['code']?.trim();
    itemCode = attributes['item_code'];
    itemTypeName = attributes['item_type_name'];
    supplierCode = attributes['supplier_code'];
    brandName = attributes['brand_name'];
    if (attributes['calculation_type'] != null) {
      calculationType = DiscountCalculationType.fromString(
        attributes['calculation_type'].toString(),
      );
    }
    if (attributes['discount_type'] != null) {
      discountType = DiscountType.fromString(
        attributes['discount_type'].toString(),
      );
    }

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
    discountFilters = DiscountFilterClass().findRelationsData(
      included: included,
      relation: relationships['discount_filters'],
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
  DateTimeRange<Date>? get purchaseDateRange {
    final discountFilter = discountFilters.firstWhereOrNull(
      (e) => e.filterKey == 'purchase_date',
    );
    if (discountFilter == null) {
      return null;
    }
    final dates = discountFilter.value
        .split('|')
        .map((value) => Date.parse(value))
        .toList();
    return DateTimeRange<Date>(start: dates.first, end: dates.last);
  }

  set purchaseDateRange(DateTimeRange<Date>? dateRange) {
    discountFilters.removeWhere((e) => e.filterKey == 'purchase_date');
    if (dateRange != null) {
      String value =
          "${dateRange.start.toIso8601String()}|${dateRange.end.toIso8601String()}";
      discountFilters.add(
        DiscountFilter(
          filterKey: 'purchase_date',
          value: value,
          isExclude: false,
        ),
      );
    }
  }

  List<Brand> get brands => discountFilters
      .where(
        (element) => element.isExclude == false && element.filterKey == 'brand',
      )
      .map<Brand>((e) => Brand(id: e.value, name: e.value))
      .toList();
  List<Brand> get blacklistBrands => discountFilters
      .where(
        (element) => element.isExclude == true && element.filterKey == 'brand',
      )
      .map<Brand>((e) => Brand(id: e.value, name: e.value))
      .toList();

  List<Item> get items => discountFilters
      .where(
        (element) => element.isExclude == false && element.filterKey == 'item',
      )
      .map<Item>((e) => Item(id: e.value, code: e.value))
      .toList();
  List<Item> get blacklistItems => discountFilters
      .where(
        (element) => element.isExclude == true && element.filterKey == 'item',
      )
      .map<Item>((e) => Item(id: e.value, code: e.value))
      .toList();

  List<Supplier> get suppliers => discountFilters
      .where(
        (element) =>
            element.isExclude == false && element.filterKey == 'supplier',
      )
      .map<Supplier>((e) => Supplier(id: e.value, code: e.value))
      .toList();
  List<Supplier> get blacklistSuppliers => discountFilters
      .where(
        (element) =>
            element.isExclude == true && element.filterKey == 'supplier',
      )
      .map<Supplier>((e) => Supplier(id: e.value, code: e.value))
      .toList();

  List<ItemType> get itemTypes => discountFilters
      .where(
        (element) =>
            element.isExclude == false && element.filterKey == 'item_type',
      )
      .map<ItemType>((e) => ItemType(id: e.value, name: e.value))
      .toList();
  List<ItemType> get blacklistItemTypes => discountFilters
      .where(
        (element) =>
            element.isExclude == true && element.filterKey == 'item_type',
      )
      .map<ItemType>((e) => ItemType(id: e.value, name: e.value))
      .toList();

  set brands(List<Brand> newBrands) {
    discountFilters.removeWhere(
      (element) => !element.isExclude && element.filterKey == 'brand',
    );
    for (final newBrand in newBrands) {
      discountFilters.add(
        DiscountFilter(filterKey: 'brand', value: newBrand.id),
      );
    }
  }

  set blacklistBrands(List<Brand> newBrands) {
    discountFilters.removeWhere(
      (element) => element.isExclude && element.filterKey == 'brand',
    );
    for (final newBrand in newBrands) {
      discountFilters.add(
        DiscountFilter(filterKey: 'brand', isExclude: true, value: newBrand.id),
      );
    }
  }

  set itemTypes(List<ItemType> newItemTypes) {
    discountFilters.removeWhere(
      (element) => !element.isExclude && element.filterKey == 'item_type',
    );
    for (final model in newItemTypes) {
      discountFilters.add(
        DiscountFilter(
          filterKey: 'item_type',
          isExclude: false,
          value: model.id,
        ),
      );
    }
  }

  set blacklistItemTypes(List<ItemType> newItemTypes) {
    discountFilters.removeWhere(
      (element) => element.isExclude && element.filterKey == 'item_type',
    );
    for (final model in newItemTypes) {
      discountFilters.add(
        DiscountFilter(
          filterKey: 'item_type',
          isExclude: true,
          value: model.id,
        ),
      );
    }
  }

  set suppliers(List<Supplier> newSuppliers) {
    discountFilters.removeWhere(
      (element) => !element.isExclude && element.filterKey == 'supplier',
    );
    for (final model in newSuppliers) {
      discountFilters.add(
        DiscountFilter(
          filterKey: 'supplier',
          isExclude: false,
          value: model.id,
        ),
      );
    }
  }

  set blacklistSuppliers(List<Supplier> newSuppliers) {
    discountFilters.removeWhere(
      (element) => element.isExclude && element.filterKey == 'supplier',
    );
    for (final model in newSuppliers) {
      discountFilters.add(
        DiscountFilter(filterKey: 'supplier', isExclude: true, value: model.id),
      );
    }
  }

  set items(List<Item> newItems) {
    discountFilters.removeWhere(
      (element) => !element.isExclude && element.filterKey == 'item',
    );
    for (final model in newItems) {
      discountFilters.add(
        DiscountFilter(filterKey: 'item', isExclude: false, value: model.id),
      );
    }
  }

  set blacklistItems(List<Item> newItems) {
    discountFilters.removeWhere(
      (element) => element.isExclude && element.filterKey == 'item',
    );
    for (final model in newItems) {
      discountFilters.add(
        DiscountFilter(filterKey: 'item', isExclude: true, value: model.id),
      );
    }
  }

  @override
  Map<String, dynamic> toMap() => {
    'code': code.trim(),
    'item_code': itemCode,
    'item_type_name': itemTypeName,
    'brand_name': brandName,
    'supplier_code': supplierCode,
    'calculation_type': calculationType,
    'discount_type': discountType,
    'customer_group': customerGroup,
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
    endTime: DateTime.now(),
  );
}
