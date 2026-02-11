import 'package:fe_pos/widget/mobile_table.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/number_form_field.dart';
export 'package:fe_pos/widget/number_form_field.dart';

class PaginationWidget extends StatefulWidget {
  final MobileTableController controller;
  // final int totalPage;
  // final int initialPage;
  // final int limit;
  final void Function(int page)? onPageChanged;
  const PaginationWidget({
    super.key,
    this.onPageChanged,
    required this.controller,
  });

  @override
  State<PaginationWidget> createState() => _PaginationWidgetState();
}

class _PaginationWidgetState extends State<PaginationWidget> {
  MobileTableController get controller => widget.controller;
  final textController = TextEditingController();

  @override
  void initState() {
    controller.addListener(() {
      textController.text = controller.currentPage.toString();
    });
    textController.text = controller.currentPage.toString();
    super.initState();
  }

  void fetchModels() {
    // controller.setValue(page);
    if (widget.onPageChanged != null) {
      widget.onPageChanged!(controller.currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [firstButton, prevButton, nextButton, lastButton],
              ),
              Row(
                spacing: 5,
                mainAxisAlignment: .center,
                children: [
                  Text('Page:'),
                  pageField,
                  Text('of ${controller.totalPage} pages'),
                ],
              ),
            ],
          );
        } else if (constraints.maxWidth < 800) {
          return Row(
            mainAxisAlignment: .spaceAround,
            children: [
              firstButton,
              prevButton,
              Text('Page:'),
              pageField,
              Text('of ${controller.totalPage} pages'),
              nextButton,
              lastButton,
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: .spaceAround,
            children: [
              firstButton,
              prevButton,
              Text('Page:'),
              pageField,
              Text('of ${controller.totalPage} pages'),
              nextButton,
              lastButton,
            ],
          );
        }
      },
    );
  }

  Widget get pageField => SizedBox(
    width: 50,
    child: NumberFormField<int>(
      controller: textController,
      isDense: true,
      onChanged: (value) {
        if (value == null) {
          controller.currentPage = 1;
          return;
        }
        if (value > 0 && value <= controller.totalPage) {
          controller.currentPage = value;
          fetchModels();
        }
      },
    ),
  );
  Widget get firstButton => IconButton(
    tooltip: 'First page',
    disabledColor: Colors.grey.shade300,
    onPressed: controller.currentPage <= 1
        ? null
        : () {
            setState(() {
              controller.currentPage = 1;
            });

            fetchModels();
          },
    icon: Icon(Icons.first_page),
  );
  Widget get prevButton => IconButton(
    tooltip: 'Previous page',
    disabledColor: Colors.grey.shade300,
    onPressed: controller.currentPage <= 1
        ? null
        : () {
            setState(() {
              controller.currentPage -= 1;
              if (controller.currentPage < 1) {
                controller.currentPage = 1;
                return;
              }
            });

            fetchModels();
          },
    icon: Icon(Icons.keyboard_arrow_left),
  );
  Widget get nextButton => IconButton(
    tooltip: 'Next page',
    disabledColor: Colors.grey.shade300,
    onPressed: controller.currentPage >= controller.totalPage
        ? null
        : () {
            setState(() {
              controller.currentPage += 1;
              if (controller.currentPage > controller.totalPage) {
                controller.currentPage = controller.totalPage;
                return;
              }
            });

            fetchModels();
          },
    icon: Icon(Icons.keyboard_arrow_right),
  );

  Widget get lastButton => IconButton(
    tooltip: 'Last page',
    disabledColor: Colors.grey.shade300,
    onPressed: controller.currentPage >= controller.totalPage
        ? null
        : () {
            setState(() {
              controller.currentPage = controller.totalPage;
            });
            fetchModels();
          },
    icon: Icon(Icons.last_page),
  );
}
