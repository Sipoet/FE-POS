import 'package:flutter/material.dart';
import 'package:fe_pos/widget/number_form_field.dart';
export 'package:fe_pos/widget/number_form_field.dart';

class PaginationWidget extends StatefulWidget {
  final TextEditingController? controller;
  final int totalPage;
  final int initialPage;
  final int limit;
  final void Function(int page)? onPageChanged;
  const PaginationWidget({
    super.key,
    this.onPageChanged,
    this.controller,
    this.limit = 10,
    this.initialPage = 1,
    this.totalPage = 1,
  });

  @override
  State<PaginationWidget> createState() => _PaginationWidgetState();
}

class _PaginationWidgetState extends State<PaginationWidget> {
  int get totalPage => widget.totalPage;
  late final TextEditingController controller;
  late int page;
  @override
  void initState() {
    page = widget.initialPage;
    controller =
        widget.controller ?? TextEditingController(text: page.toString());
    super.initState();
  }

  void fetchModels() {
    controller.setValue(page);
    if (widget.onPageChanged != null) {
      widget.onPageChanged!(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .max,
      mainAxisAlignment: .spaceEvenly,
      children: [
        IconButton(
          tooltip: 'First page',
          disabledColor: Colors.grey.shade300,
          onPressed: page <= 1
              ? null
              : () {
                  setState(() {
                    page = 1;
                  });

                  fetchModels();
                },
          icon: Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: 'Previous page',
          disabledColor: Colors.grey.shade300,
          onPressed: page <= 1
              ? null
              : () {
                  setState(() {
                    page -= 1;
                    if (page < 1) {
                      page = 1;
                      return;
                    }
                  });

                  fetchModels();
                },
          icon: Icon(Icons.keyboard_arrow_left),
        ),
        Text('Page:'),
        SizedBox(
          width: 50,
          child: NumberFormField<int>(
            controller: controller,
            isDense: true,
            onChanged: (value) {
              if (value == null) {
                controller.setValue(page);
                return;
              }
              if (value > 0 && value <= totalPage) {
                page = value;
                fetchModels();
              }
            },
          ),
        ),
        Text('of $totalPage pages'),
        IconButton(
          tooltip: 'Next page',
          disabledColor: Colors.grey.shade300,
          onPressed: page >= totalPage
              ? null
              : () {
                  setState(() {
                    page += 1;
                    if (page > totalPage) {
                      page = totalPage;
                      return;
                    }
                  });

                  fetchModels();
                },
          icon: Icon(Icons.keyboard_arrow_right),
        ),
        IconButton(
          tooltip: 'Last page',
          disabledColor: Colors.grey.shade300,
          onPressed: page >= totalPage
              ? null
              : () {
                  setState(() {
                    page = totalPage;
                  });
                  fetchModels();
                },
          icon: Icon(Icons.last_page),
        ),
      ],
    );
  }
}
