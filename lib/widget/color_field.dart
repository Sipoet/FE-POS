import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorField extends StatefulWidget {
  final Color? initialValue;
  final void Function(Color color)? onChanged;
  const ColorField({
    super.key,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<ColorField> {
  late Color color;

  @override
  void initState() {
    color = widget.initialValue ?? Colors.transparent;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: ElevatedButton(
        style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            shape: WidgetStateProperty.all(BeveledRectangleBorder(
                side: BorderSide(width: 0.5, color: colorScheme.outline),
                borderRadius: BorderRadius.all(Radius.circular(3)))),
            padding: WidgetStateProperty.all(EdgeInsets.all(10))),
        onPressed: _openColorPickerDialog,
        child: Row(
          children: [
            Card(
              color: color,
              child: SizedBox(
                width: 35,
                height: 35,
              ),
            ),
            Text(color.toHexString()),
          ],
        ),
      ),
    );
  }

  void _openColorPickerDialog() {
    showDialog<Color>(
        context: context,
        builder: (BuildContext builder) {
          final navigator = Navigator.of(builder);
          Color selectColor = color;
          return AlertDialog(
              title: const Text('Pick a color!'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ColorPicker(
                      pickerColor: color,
                      enableAlpha: false,
                      labelTypes: [],
                      paletteType: PaletteType.hueWheel,
                      displayThumbColor: true,
                      portraitOnly: true,
                      onColorChanged: (Color newColor) {
                        selectColor = newColor;
                      },
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                        onPressed: () => navigator.pop(selectColor),
                        child: Text('Pilih')),
                  ],
                ),
              ));
        }).then((Color? newColor) => setState(() {
          color = newColor ?? color;
          if (widget.onChanged != null && newColor != null) {
            widget.onChanged!(color);
          }
        }));
  }
}
