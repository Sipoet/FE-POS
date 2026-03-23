import 'package:fe_pos/tool/table_decorator.dart';

import 'package:flutter/material.dart';

export 'package:fe_pos/tool/query_data.dart';

typedef FilterProcess = void Function(List<FilterData>);

class TableFilterForm extends StatefulWidget {
  final List<TableColumn> columns;
  final Map<String, List<dynamic>> enums;
  final TableFilterFormController? controller;
  final FilterProcess onSubmit;
  final FilterProcess? onDownload;
  final bool showCanopy;
  const TableFilterForm({
    super.key,
    this.enums = const {},
    required this.onSubmit,
    this.onDownload,
    required this.columns,
    this.showCanopy = true,
    this.controller,
  });

  @override
  State<TableFilterForm> createState() => _TableFilterFormState();
}

class _TableFilterFormState extends State<TableFilterForm> {
  final _key = GlobalKey<FormState>();
  final _labelStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );
  late final TableFilterFormController controller;
  late ColorScheme colorScheme;
  bool isShowFilter = false;

  @override
  void initState() {
    isShowFilter = !widget.showCanopy;
    controller = widget.controller ?? TableFilterFormController();
    super.initState();
  }

  final borderRadius = BorderRadius.only(
    topLeft: Radius.circular(15),
    topRight: Radius.circular(15),
  );
  void _openFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colorScheme.outline),
      ),
      scrollControlDisabledMaxHeightRatio: 600,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final filterForms = widget.columns
            .where((element) => element.canFilter)
            .map<Widget>((column) => formFilter(column))
            .toList();
        final navigator = Navigator.of(context);
        return SizedBox(
          height: size.height * 2 / 3,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder.symmetric(
                    horizontal: BorderSide(color: colorScheme.outline),
                  ),
                  borderRadius: borderRadius,
                  color: colorScheme.secondaryContainer,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text("Filter", style: _labelStyle),
                      IconButton(
                        onPressed: () => navigator.pop(),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 10.0,
                    left: 10,
                    right: 10,
                    bottom: 5,
                  ),
                  child: Center(
                    child: Form(
                      key: _key,
                      child: ListView.separated(
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) => filterForms[index],
                        itemCount: filterForms.length,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(minWidth: size.width - 1),
                decoration: BoxDecoration(
                  border: BoxBorder.symmetric(
                    horizontal: BorderSide(color: colorScheme.outline),
                  ),
                  color: colorScheme.secondaryContainer,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Wrap(
                    runSpacing: 10.0,
                    spacing: 10,
                    alignment: .spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_key.currentState!.validate()) {
                            _key.currentState!.save();
                            widget.onSubmit(controller.decoratedFilter);
                            navigator.pop();
                          }
                        },
                        child: const Text('Cari'),
                      ),
                      Visibility(
                        visible: widget.onDownload != null,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_key.currentState!.validate()) {
                              _key.currentState!.save();
                              widget.onDownload!(controller.decoratedFilter);
                              navigator.pop();
                            }
                          },
                          child: const Text('Download'),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          controller.removeAllFilter();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return IconButton.outlined(
            onPressed: _openFilterDialog,
            icon: Icon(
              Icons.filter_alt,
              color: controller.decoratedFilter.isNotEmpty
                  ? Colors.green
                  : null,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, bottom: 10),
              child: Text("Filter", style: _labelStyle),
            ),
            Visibility(
              visible: widget.showCanopy,
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isShowFilter = !isShowFilter;
                        });
                      },
                      icon: Icon(
                        isShowFilter ? Icons.expand_more : Icons.expand_less,
                      ),
                      label: const Divider(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Visibility(
              visible: isShowFilter,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Form(
                    key: _key,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Wrap(
                          runSpacing: 10.0,
                          spacing: 10.0,
                          children: widget.columns
                              .where((element) => element.canFilter)
                              .map<Widget>((column) => formFilter(column))
                              .toList(),
                        ),
                        const Divider(),
                        Wrap(
                          runSpacing: 10.0,
                          spacing: 10.0,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_key.currentState!.validate()) {
                                    _key.currentState!.save();
                                    widget.onSubmit(controller.decoratedFilter);
                                  }
                                },
                                child: const Text('Cari'),
                              ),
                            ),
                            Visibility(
                              visible: widget.onDownload != null,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_key.currentState!.validate()) {
                                      _key.currentState!.save();
                                      widget.onDownload!(
                                        controller.decoratedFilter,
                                      );
                                    }
                                  },
                                  child: const Text('Download'),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  controller.removeAllFilter();
                                },
                                child: const Text('Reset'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget formFilter(TableColumn column) {
    FilterFormController? formController = controller.controllerOfColumn(
      column.name,
    );
    if (formController == null) {
      formController = FilterFormController(null);
      controller.setFilter(column.name, formController);
    }

    return column.type.renderFilter(
      key: ValueKey('filter-${column.name}-field'),
      name: column.name,
      label: Text(column.humanizeName, style: _labelStyle),
      controller: formController,
    );
  }
}

class TableFilterFormController {
  final Map<String, FilterFormController> _filter = {};

  void setFilter(String key, FilterFormController controller) {
    _filter[key] = controller;
  }

  void removeFilter(String key) {
    _filter[key]?.clear();
  }

  FilterFormController? controllerOfColumn(String key) {
    return _filter[key];
  }

  void removeAllFilter() {
    for (final controller in controllers) {
      controller.clear();
    }
  }

  List<FilterFormController> get controllers => _filter.values.toList();

  List<FilterData> get decoratedFilter => _filter.values
      .where((e) => e.value != null)
      .map<FilterData>((controller) => controller.value!)
      .toList();
}

extension FilterText on TextEditingController {
  void clear() {
    text = '';
  }
}
