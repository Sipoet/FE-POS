import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';

class DateFormField extends StatefulWidget {
  final DateTime? initialValue;
  final Widget? label;
  final String? helpText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool allowClear;
  final bool datePickerOnly;
  final FocusNode? focusNode;
  final void Function(DateTime?)? onSaved;
  final void Function(DateTime? date)? onChanged;
  final String? Function(DateTime?)? validator;
  const DateFormField(
      {super.key,
      this.label,
      this.datePickerOnly = false,
      this.firstDate,
      this.lastDate,
      this.helpText,
      this.onSaved,
      this.focusNode,
      this.onChanged,
      this.validator,
      this.allowClear = false,
      this.initialValue});

  @override
  State<DateFormField> createState() => _DateFormFieldState();
}

class _DateFormFieldState extends State<DateFormField> with TextFormatter {
  DateTime? _datetime;

  final _controller = TextEditingController();

  @override
  void initState() {
    _datetime = widget.initialValue;
    writeToTextField();
    super.initState();
  }

  final minDate = DateTime(1900);
  final maxDate = DateTime(99999);

  void _openDialog() {
    showBoardDateTimePicker(
            context: context,
            options: BoardDateTimeOptions(
                pickerFormat: PickerFormat.dmy,
                startDayOfWeek: DateTime.monday,
                boardTitle: widget.helpText,
                languages: const BoardPickerLanguages(
                    today: 'Hari ini',
                    tomorrow: 'Besok',
                    now: 'Sekarang',
                    locale: 'id')),
            initialDate: widget.initialValue,
            minimumDate: minDate,
            maximumDate: maxDate,
            pickerType: widget.datePickerOnly
                ? DateTimePickerType.date
                : DateTimePickerType.datetime,
            breakpoint: 1000)
        .then((date) {
      setState(() {
        _datetime = date;
        writeToTextField();
        if (widget.onChanged != null) {
          widget.onChanged!(_datetime);
        }
      });
    });
  }

  void writeToTextField() {
    if (_datetime == null) {
      _controller.text = '';
    } else if (widget.datePickerOnly) {
      _controller.text = dateFormat(_datetime!);
    } else {
      _controller.text = dateTimeFormat(_datetime!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onTap: () {
        _openDialog();
      },
      focusNode: widget.focusNode,
      readOnly: true,
      validator: (value) {
        if (widget.validator == null) {
          return null;
        }
        return widget.validator!(_datetime);
      },
      onSaved: (newValue) {
        widget.onSaved!(_datetime);
      },
      decoration: InputDecoration(
        label: widget.label,
        contentPadding: EdgeInsets.all(5),
        border: const OutlineInputBorder(),
        suffix: widget.allowClear
            ? IconButton(
                iconSize: 20,
                onPressed: () {
                  setState(() {
                    _datetime = null;
                    writeToTextField();
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(_datetime);
                  }
                },
                icon: const Icon(Icons.close))
            : null,
      ),
      controller: _controller,
    );
  }
}
