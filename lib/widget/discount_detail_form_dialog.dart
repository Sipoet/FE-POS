import 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/tool/model_route.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/percentage_form_field.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:flutter/material.dart';

class DiscountDetailFormDialog extends StatefulWidget {
  final TabManager tabManager;
  final List<DiscountDetail> discountDetails;
  final NavigatorState navigator;
  final List<Widget> descriptions;
  const DiscountDetailFormDialog({
    super.key,
    required this.tabManager,
    required this.navigator,
    this.descriptions = const [],
    List<DiscountDetail>? discountDetails,
  }) : discountDetails = discountDetails ?? const [];

  @override
  State<DiscountDetailFormDialog> createState() =>
      _DiscountDetailFormDialogState();
}

class _DiscountDetailFormDialogState extends State<DiscountDetailFormDialog>
    with TextFormatter {
  final scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  List<DiscountDetail> discountDetails = [];
  NavigatorState get navigator => widget.navigator;
  TabManager get tabManager => widget.tabManager;
  final router = ModelRoute();

  @override
  void initState() {
    discountDetails = widget.discountDetails
        .map<DiscountDetail>(
          (e) => DiscountDetail(type: e.type, value: e.value),
        )
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Form(
      key: _formKey,
      autovalidateMode: .always,
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Flexible(child: Text('Detail Diskon')),
            IconButton(
              onPressed: () => navigator.pop(),
              icon: Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          height: size.height - 30,
          width: size.width - 30,
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 8,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  ...widget.descriptions,
                  TableForm<DiscountDetail>(
                    columnSpacing: 10,
                    columns: [
                      TableFormColumn<DiscountDetail>(
                        title: 'Tipe',
                        headerBuilder: (context) => Text(
                          'Tipe',
                          textAlign: .right,
                          style: TextFormatter.titleStyle,
                        ),
                        rowBuilder: (context, object, index) =>
                            DropdownMenu<DiscountDetailType>(
                              width: 150,
                              onSelected: (value) => setState(() {
                                object.type = value ?? object.type;
                              }),
                              initialSelection: object.type,
                              dropdownMenuEntries: DiscountDetailType.values
                                  .map<DropdownMenuEntry<DiscountDetailType>>(
                                    (value) =>
                                        DropdownMenuEntry<DiscountDetailType>(
                                          value: value,
                                          label: value.humanize(),
                                        ),
                                  )
                                  .toList(),
                            ),
                      ),
                      TableFormColumn<DiscountDetail>(
                        title: 'Value',
                        headerBuilder: (context) => Text(
                          'Value',
                          textAlign: .right,
                          style: TextFormatter.titleStyle,
                        ),
                        rowBuilder: (context, object, index) {
                          if (object.type == .percentage) {
                            return PercentageFormField(
                              initialValue: Percentage(object.value),
                              onChanged: (value) =>
                                  object.value = value?.value ?? 0,
                            );
                          } else if (object.type == .nominal) {
                            return MoneyFormField(
                              initialValue: Money(object.value),
                              onChanged: (value) =>
                                  object.value = value?.value ?? 0,
                            );
                          } else {
                            return NumberFormField<double>(
                              initialValue: object.value,
                              onChanged: (value) => object.value = value ?? 0,
                            );
                          }
                        },
                      ),
                    ],
                    rows: discountDetails,
                    actionColumn: TableFormColumn<DiscountDetail>(
                      desktopWidth: FixedColumnWidth(130),
                      headerBuilder: (context) => Row(
                        mainAxisAlignment: .end,
                        spacing: 20,
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              discountDetails.add(DiscountDetail());
                            }),
                            icon: Icon(Icons.add),
                          ),

                          IconButton(
                            onPressed: () => setState(() {
                              discountDetails.clear();
                            }),
                            icon: Icon(Icons.delete),
                          ),
                        ],
                      ),
                      rowBuilder: (context, object, index) => IconButton(
                        onPressed: () => setState(() {
                          discountDetails.remove(object);
                        }),
                        icon: Icon(Icons.delete),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: .all(15),
        actionsAlignment: .start,
        actionsOverflowButtonSpacing: 20,
        actionsOverflowAlignment: .start,
        actionsOverflowDirection: .down,
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() != true) {
                return;
              }
              _formKey.currentState?.save();
              navigator.pop(discountDetails);
            },

            child: Text('Edit'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () => navigator.pop(),
            child: Text('Batal'),
          ),
        ],
      ),
    );
  }
}
