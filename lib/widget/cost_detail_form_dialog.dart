import 'package:collection/collection.dart';
import 'package:fe_pos/model/cost_detail.dart';
import 'package:fe_pos/tool/model_route.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:flutter/material.dart';

class CostDetailFormDialog extends StatefulWidget {
  final void Function(List<CostDetail>) onSuccess;
  final TabManager tabManager;
  final List<CostDetail> costDetails;
  final NavigatorState navigator;
  CostDetailFormDialog({
    super.key,
    required this.tabManager,
    required this.navigator,
    List<CostDetail>? costDetails,
    required this.onSuccess,
  }) : costDetails = costDetails ?? [];

  @override
  State<CostDetailFormDialog> createState() => _CostDetailFormDialogState();
}

class _CostDetailFormDialogState extends State<CostDetailFormDialog>
    with TextFormatter {
  final scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  List<CostDetail> get costDetails => widget.costDetails;
  NavigatorState get navigator => widget.navigator;
  TabManager get tabManager => widget.tabManager;
  final router = ModelRoute();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: .always,
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Flexible(child: Text('Detail Biaya lain')),
            IconButton(
              onPressed: () => navigator.pop(),
              icon: Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          height: 1000,
          width: 1000,
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 8,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: TableForm<CostDetail>(
                columnSpacing: 10,
                columns: [
                  TableFormColumn<CostDetail>(
                    name: 'source_cost',
                    headerBuilder: (context) => Text(
                      'Sumber Biaya',
                      textAlign: .right,
                      style: TextFormatter.titleStyle,
                    ),
                    rowBuilder: (context, object) => object.sourceCostId == null
                        ? SizedBox()
                        : TextButton(
                            onPressed: () {
                              if (object.sourceCost == null) {
                                return;
                              }
                              final detailPage = router.detailPageOf(
                                object.sourceCost!,
                              );
                              if (detailPage == null) {
                                return;
                              }
                              tabManager.addTab(
                                'Edit ${object.sourceCostId}',
                                detailPage,
                              );
                            },
                            child: Text(
                              '${object.sourceCostType} ${object.sourceCostId}',
                            ),
                          ),
                  ),
                  TableFormColumn<CostDetail>(
                    name: 'description',
                    headerBuilder: (context) => Text(
                      'Deskripsi',
                      textAlign: .right,
                      style: TextFormatter.titleStyle,
                    ),
                    rowBuilder: (context, object) => TextFormField(
                      initialValue: object.description,
                      keyboardType: .multiline,
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      minLines: 1,
                      maxLines: 5,
                      onChanged: (value) => object.description = value,
                    ),
                  ),
                  TableFormColumn<CostDetail>(
                    name: 'amount',
                    headerBuilder: (context) => Text(
                      'Jumlah(Rp)',
                      textAlign: .right,
                      style: TextFormatter.titleStyle,
                    ),
                    rowBuilder: (context, object) => MoneyFormField(
                      initialValue: object.amount,
                      validator: (value) {
                        if (value == null) {
                          return 'harus diisi';
                        }
                        return null;
                      },
                      onChanged: (value) =>
                          object.amount = value ?? const Money(0),
                    ),
                  ),
                ],
                rows: costDetails.whereNot((e) => e.isDestroyed).toList(),
                actionColumn: TableFormColumn<CostDetail>(
                  name: 'action',
                  desktopWidth: FixedColumnWidth(130),
                  headerBuilder: (context) => Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          costDetails.add(CostDetail());
                        }),
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                  rowBuilder: (context, object) => Visibility(
                    visible: object.sourceCost == null,
                    child: IconButton(
                      onPressed: () => setState(() {
                        if (object.isNewRecord) {
                          costDetails.remove(object);
                        } else {
                          object.flagDestroy();
                        }
                      }),
                      icon: Icon(Icons.delete),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        actionsOverflowButtonSpacing: 20,
        actionsOverflowAlignment: .start,
        actionsOverflowDirection: .down,
        actionsPadding: .all(15),
        actionsAlignment: .start,
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() != true) {
                return;
              }
              widget.onSuccess.call(costDetails);
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
