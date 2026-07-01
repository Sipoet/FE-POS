import 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class EnumDropdown<T extends EnumTranslation> extends StatelessWidget {
  final List<T> values;
  final Widget? label;
  final T? initialSelection;
  final void Function(T? values)? onChanged;
  final bool allowClear;
  final bool? isDense;
  final double? width;
  final String? Function(T?)? validator;
  final void Function(T?)? onSaved;
  const EnumDropdown({
    super.key,
    this.label,
    this.isDense,
    this.width,
    this.validator,
    this.onSaved,
    this.initialSelection,
    this.allowClear = false,
    required this.values,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      validator: validator,
      onSaved: onSaved,
      builder: (state) => DropdownMenu<T>(
        width: width,
        label: label,
        onSelected: (value) {
          state.didChange(value);
          onChanged?.call(value);
        },
        errorText: state.errorText,
        initialSelection: initialSelection,
        inputDecorationTheme: InputDecorationTheme(
          isDense: isDense,
          border: OutlineInputBorder(),
        ),
        dropdownMenuEntries: values
            .map<DropdownMenuEntry<T>>(
              (value) =>
                  DropdownMenuEntry<T>(value: value, label: value.humanize()),
            )
            .toList(),
      ),
    );
  }
}
