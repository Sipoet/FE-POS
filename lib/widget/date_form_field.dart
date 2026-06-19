import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';

abstract class DateFormType<T> {
  const DateFormType();
  String displayFormat(T date);
  Future<T?> showDialog({
    required BuildContext context,
    required ColorScheme colorScheme,
    String? helpText,
    T? initialDate,
  });
}

class DateType with TextFormatter implements DateFormType<Date> {
  const DateType();
  @override
  String displayFormat(Date date) {
    return dateFormat(date);
  }

  @override
  Future<Date?> showDialog({
    required BuildContext context,
    required ColorScheme colorScheme,
    String? helpText,
    DateTime? initialDate,
  }) {
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
          locale: 'id',
        ),
      ),
      initialDate: initialDate?.toLocal(),
      pickerType: DateTimePickerType.date,
    ).then((result) => result?.toDate());
  }
}

class DateTimeType with TextFormatter implements DateFormType<DateTime> {
  const DateTimeType();
  @override
  String displayFormat(DateTime date) {
    return dateTimeFormat(date);
  }

  @override
  Future<DateTime?> showDialog({
    required BuildContext context,
    required ColorScheme colorScheme,
    String? helpText,
    DateTime? initialDate,
  }) {
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
          locale: 'id',
        ),
      ),
      initialDate: initialDate?.toLocal(),
      pickerType: DateTimePickerType.datetime,
    );
  }
}

class TimeType with TextFormatter implements DateFormType<TimeOfDay> {
  const TimeType();
  @override
  String displayFormat(TimeOfDay time) {
    return timeFormat(time);
  }

  @override
  Future<TimeOfDay?> showDialog({
    required BuildContext context,
    required ColorScheme colorScheme,
    String? helpText,
    TimeOfDay? initialDate,
  }) {
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
          locale: 'id',
        ),
      ),
      initialDate: initialDate == null
          ? null
          : DateTime.now().toLocal().copyWith(
              hour: initialDate.hour,
              minute: initialDate.minute,
            ),
      pickerType: DateTimePickerType.time,
    ).then((result) => result == null ? null : TimeOfDay.fromDateTime(result));
  }
}

class DateFormField<T> extends StatefulWidget {
  final T? initialValue;
  final Widget? label;
  final String? helpText;
  final T? firstDate;
  final T? lastDate;
  final bool allowClear;
  final DateFormType? dateType;
  final bool? readOnly;
  final bool? isDense;
  final FocusNode? focusNode;
  final DateEditingController<T>? controller;
  final void Function(T?)? onSaved;
  final void Function(T? date)? onChanged;
  final String? Function(T?)? validator;
  const DateFormField({
    super.key,
    this.label,
    this.dateType,
    this.firstDate,
    this.controller,
    this.lastDate,
    this.helpText,
    this.isDense,
    this.onSaved,
    this.readOnly,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.allowClear = false,
    this.initialValue,
  });

  @override
  State<DateFormField<T>> createState() => _DateFormFieldState<T>();
}

class _DateFormFieldState<T> extends State<DateFormField<T>>
    with TextFormatter {
  T? _datetime;

  late final DateFormType dateType;

  final _controller = TextEditingController();

  @override
  void initState() {
    dateType = widget.dateType ?? _dateTypeBasedType();
    _datetime = widget.initialValue ?? widget.controller?.value;
    widget.controller?.addListener(() {
      setState(() {
        _datetime = widget.controller?.value;
        _controller.text = _datetime == null
            ? ''
            : dateType.displayFormat(_datetime!);
      });
    });
    writeToTextField();
    super.initState();
  }

  DateFormType _dateTypeBasedType() {
    if (T == Date) {
      return DateType();
    } else if (T == DateTime) {
      return DateTimeType();
    } else if (T == TimeOfDay) {
      return TimeType();
    } else {
      throw '${T.runtimeType} not supported';
    }
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
            widget.onChanged?.call(date);
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
        if (widget.readOnly == true) {
          return;
        }
        _openDialog();
      },
      focusNode: widget.focusNode,
      readOnly: true,
      validator: (value) {
        return widget.validator?.call(_datetime);
      },
      onSaved: (newValue) {
        widget.onSaved?.call(_datetime);
      },
      decoration: InputDecoration(
        label: widget.label,
        isDense: widget.isDense,
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

                  widget.onChanged?.call(null);
                },
                icon: const Icon(Icons.close),
              )
            : null,
      ),
      controller: _controller,
    );
  }
}

class DateEditingController<T> extends ValueNotifier<T?> {
  DateEditingController(super.value);

  void clear() {
    value = null;
    notifyListeners();
  }
}
