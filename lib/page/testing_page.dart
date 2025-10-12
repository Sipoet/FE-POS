import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';

class TestingPage extends StatefulWidget {
  const TestingPage({super.key});

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
  int acceptedData = 0;

  Widget pillWidget(numFlag) {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 40,
      width: numFlag * 30.0,
      color: Colors.blue,
      child: Text(
        "no ${numFlag.toString()}",
        style: const TextStyle(color: Colors.black, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            children: [
              Container(
                  padding: const EdgeInsets.only(right: 10),
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: AsyncDropdownMultiple<Brand>(
                    label: const Text('Merek :'),
                    key: const ValueKey('brandSelect'),
                    textOnSearch: (Brand brand) => brand.name,
                    modelClass: BrandClass(),
                    attributeKey: 'merek',
                    path: '/brands',
                    onChanged: (value) {
                      debugPrint("list: ${value.toString()}");
                    },
                  )),
              Draggable<int>(
                // Data is the value this Draggable stores.
                data: 10,
                feedback: Container(
                  color: Colors.deepOrange,
                  height: 100,
                  width: 100,
                  child: const Text(
                    'feedback dragged',
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: 12,
                        color: Colors.black),
                  ),
                ),
                childWhenDragging: Container(
                  height: 100.0,
                  width: 100.0,
                  color: Colors.pinkAccent,
                  child: const Center(
                    child: Text('Child When Dragging'),
                  ),
                ),
                child: Container(
                  height: 100.0,
                  width: 100.0,
                  color: Colors.lightGreenAccent,
                  child: const Center(
                    child: Text('Draggable'),
                  ),
                ),
              ),
              DragTarget<int>(
                builder: (
                  BuildContext context,
                  List<dynamic> accepted,
                  List<dynamic> rejected,
                ) {
                  return Container(
                    height: 100.0,
                    width: 100.0,
                    color: Colors.cyan,
                    child: Center(
                      child: Text('Value is updated to: $acceptedData'),
                    ),
                  );
                },
                onAcceptWithDetails: (DragTargetDetails<int> details) {
                  setState(() {
                    acceptedData += details.data;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
