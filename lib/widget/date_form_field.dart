import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';

class DateType with TextFormatter {
  const DateType();
  String displayFormat(DateTime date) {
    return dateFormat(date);
  }

  Future<DateTime?> showDialog(
      {required BuildContext context,
      required ColorScheme colorScheme,
      String? helpText,
      DateTime? initialDate}) {
    return showBoardDateTimePicker(
      context: context,
      showDragHandle: false,
      enableDrag: false,
      options: BoardDateTimeOptions(
          pickerFormat: PickerFormat.dmy,
          startDayOfWeek: DateTime.monday,
          boardTitle: helpText,
          useAmpm: false,
          languages: const BoardPickerLanguages(
              today: 'Hari ini',
              tomorrow: 'Besok',
              now: 'Sekarang',
              locale: 'id')),
      initialDate: initialDate,
      pickerType: DateTimePickerType.date,
    );
  }
}

class DateTimeType with TextFormatter implements DateType {
  const DateTimeType();
  @override
  String displayFormat(DateTime date) {
    return dateTimeFormat(date);
  }

  @override
  Future<DateTime?> showDialog(
      {required BuildContext context,
      required ColorScheme colorScheme,
      String? helpText,
      DateTime? initialDate}) {
    return showBoardDateTimePicker(
      context: context,
      showDragHandle: false,
      enableDrag: false,
      options: BoardDateTimeOptions(
          pickerFormat: PickerFormat.dmy,
          startDayOfWeek: DateTime.monday,
          boardTitle: helpText,
          useAmpm: false,
          languages: const BoardPickerLanguages(
              today: 'Hari ini',
              tomorrow: 'Besok',
              now: 'Sekarang',
              locale: 'id')),
      initialDate: initialDate,
      pickerType: DateTimePickerType.datetime,
    );
  }
}

class TimeType with TextFormatter implements DateType {
  const TimeType();
  @override
  String displayFormat(DateTime date) {
    return timeFormat(TimeOfDay.fromDateTime(date));
  }

  @override
  Future<DateTime?> showDialog(
      {required BuildContext context,
      required ColorScheme colorScheme,
      String? helpText,
      DateTime? initialDate}) {
    return showBoardDateTimePicker(
      context: context,
      showDragHandle: false,
      enableDrag: false,
      options: BoardDateTimeOptions(
          pickerFormat: PickerFormat.dmy,
          startDayOfWeek: DateTime.monday,
          boardTitle: helpText,
          useAmpm: false,
          languages: const BoardPickerLanguages(
              today: 'Hari ini',
              tomorrow: 'Besok',
              now: 'Sekarang',
              locale: 'id')),
      initialDate: initialDate,
      pickerType: DateTimePickerType.time,
    );
  }
}

class DateFormField extends StatefulWidget {
  final DateTime? initialValue;
  final Widget? label;
  final String? helpText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool allowClear;
  final DateType dateType;
  final FocusNode? focusNode;
  final DateEditingController? controller;
  final void Function(DateTime?)? onSaved;
  final void Function(DateTime? date)? onChanged;
  final String? Function(DateTime?)? validator;
  const DateFormField(
      {super.key,
      this.label,
      this.dateType = const DateType(),
      this.firstDate,
      this.controller,
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

  DateType get dateType => widget.dateType;

  final _controller = TextEditingController();

  @override
  void initState() {
    _datetime = widget.initialValue;
    widget.controller?.addListener(() {
      setState(() {
        _datetime = widget.controller?.value;
        _controller.text =
            _datetime == null ? '' : dateType.displayFormat(_datetime!);
      });
    });
    writeToTextField();
    super.initState();
  }

  final minDate = DateTime(1900);
  final maxDate = DateTime(9999);

  void _openDialog() {
    dateType
        .showDialog(
      context: context,
      colorScheme: Theme.of(context).colorScheme,
      initialDate: _datetime,
      helpText: widget.helpText,
    )
        .then((date) {
      if (date == null) {
        return;
      }
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
    } else {
      _controller.text = dateType.displayFormat(_datetime!);
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

class DateEditingController extends ValueNotifier<DateTime?> {
  DateEditingController(super.value);

  void clear() {
    value = null;
    notifyListeners();
  }
}
