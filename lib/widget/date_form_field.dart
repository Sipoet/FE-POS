import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DateFormField extends StatefulWidget {
  final DateTime? initialValue;
  final Widget? label;
  final String? helpText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool canRemove;
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
      this.canRemove = false,
      required this.initialValue});

  @override
  State<DateFormField> createState() => _DateFormFieldState();
}

class _DateFormFieldState extends State<DateFormField> {
  DateTime? _datetime;

  final _controller = TextEditingController();
  late final Setting _setting;

  @override
  void initState() {
    _setting = context.read<Setting>();
    _datetime = widget.initialValue;
    writeToTextField();
    super.initState();
  }

  void _openDialog() {
    final time = _datetime != null
        ? TimeOfDay.fromDateTime(_datetime!)
        : TimeOfDay.now();
    showDatePicker(
      helpText: widget.helpText,
      context: context,
      initialDate: _datetime,
      cancelText: 'Batal',
      confirmText: 'OK',
      initialEntryMode: DatePickerEntryMode.calendar,
      firstDate: DateTime(1945),
      lastDate: DateTime(9999),
    ).then((date) {
      if (date == null) {
        return;
      }
      if (widget.datePickerOnly) {
        _selectDate(date: date);
      } else {
        showTimePicker(
          helpText: widget.helpText,
          context: context,
          initialTime: time,
          hourLabelText: 'Jam',
          minuteLabelText: 'Menit',
          cancelText: 'Batal',
          confirmText: 'OK',
          initialEntryMode: TimePickerEntryMode.dial,
        ).then((time) {
          if (time != null) {
            _selectDate(date: date, time: time);
          }
        });
      }
    });
  }

  void _selectDate({required DateTime date, TimeOfDay? time}) {
    setState(() {
      _datetime = date;
      if (time != null) {
        _datetime = _datetime!.copyWith(hour: time.hour, minute: time.minute);
      }
      writeToTextField();
    });
    if (widget.onChanged != null) {
      widget.onChanged!(_datetime);
    }
  }

  void writeToTextField() {
    if (_datetime == null) {
      _controller.text = '';
    } else if (widget.datePickerOnly) {
      _controller.text = _setting.dateFormat(_datetime!);
    } else {
      _controller.text = _setting.dateTimeFormat(_datetime!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Stack(children: [
          TextFormField(
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
                label: widget.label, border: const OutlineInputBorder()),
            controller: _controller,
          ),
          Visibility(
              visible: widget.canRemove && _datetime != null,
              child: Positioned(
                top: 1,
                right: 5,
                child: IconButton(
                    iconSize: 30,
                    onPressed: () {
                      setState(() {
                        _datetime = null;
                        writeToTextField();
                      });
                      if (widget.onChanged != null) {
                        widget.onChanged!(_datetime);
                      }
                    },
                    icon: const Icon(Icons.close)),
              )),
        ]));
  }
}
