import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

abstract class RangeType<T extends DateTime> {
  const RangeType();
  String displayFormat(DateTimeRange<T> range);
  Future<DateTimeRange<T>?> showDialog({
    required BuildContext context,
    required ColorScheme colorScheme,
    String? helpText,
    DateTimeRange<T>? initialValue,
  });

  T? convert(dynamic value);
}

class DateTimeRangeType implements RangeType<DateTime> {
  const DateTimeRangeType();

  @override
  String displayFormat(DateTimeRange range) {
    var formater = DateFormat('dd/MM/y');
    if (range.isSameDay) {
      var hourFormat = DateFormat('HH:mm');
      return "${formater.format(range.start)} ${hourFormat.format(range.start)} - ${hourFormat.format(range.end)}";
    } else {
      final formater = DateFormat('dd/MM/y HH:mm');
      return "${formater.format(range.start)} - ${formater.format(range.end)}";
    }
  }

  @override
  DateTime? convert(dynamic value) =>
      value is DateTime ? value : DateTime.tryParse(value.toString());

  @override
  Future<DateTimeRange?> showDialog({
    required BuildContext context,
    required ColorScheme colorScheme,
    String? helpText,
    DateTimeRange? initialValue,
  }) {
    return showBoardDateTimeMultiPicker(
      context: context,
      options: BoardDateTimeOptions(
        withSecond: false,
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
      startDate: initialValue?.start,
      endDate: initialValue?.end,
      showDragHandle: false,
      enableDrag: false,
      pickerType: DateTimePickerType.datetime,
    ).then((dateTimeRange) {
      if (dateTimeRange != null) {
        return DateTimeRange(
          start: dateTimeRange.start.toLocal(),
          end: dateTimeRange.end.toLocal(),
        );
      }
      return null;
    });
  }
}

class DateRangeType implements RangeType<Date> {
  const DateRangeType();
  @override
  String displayFormat(DateTimeRange range) {
    final formater = DateFormat('dd/MM/y');
    return "${formater.format(range.start)} - ${formater.format(range.end)}";
  }

  @override
  Date? convert(dynamic value) =>
      value is Date ? value : Date.tryParse(value.toString());

  @override
  Future<DateTimeRange<Date>?> showDialog({
    required BuildContext context,
    required ColorScheme colorScheme,
    String? helpText,
    DateTimeRange? initialValue,
  }) {
    return showDateRangePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      fieldStartHintText: 'Mulai',
      fieldEndHintText: 'Akhir',
      initialDateRange: initialValue,
      currentDate: DateTime.now(),
      firstDate: DateTime(1000),
      lastDate: DateTime.now().add(Duration(days: 36500)),
      // useRootNavigator: false,
      initialEntryMode: DatePickerEntryMode.calendar,
    ).then((onValue) {
      if (onValue == null) {
        return null;
      }
      return DateTimeRange<Date>(
        start: onValue.start.toDate(),
        end: onValue.end.toDate(),
      );
    });
  }
}

class MonthRangeType implements RangeType<DateTime> {
  const MonthRangeType();
  @override
  String displayFormat(DateTimeRange range) {
    if (range.isSameYear) {
      final formatter = DateFormat('MMMM');
      return '${formatter.format(range.start)} - ${formatter.format(range.end)} ${range.start.year.toString()}';
    } else {
      final formatter = DateFormat('MMMM y');
      return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
    }
  }

  @override
  DateTime? convert(dynamic value) =>
      value is DateTime ? value : DateTime.tryParse(value.toString());
  @override
  Future<DateTimeRange?> showDialog({
    required BuildContext context,
    required ColorScheme colorScheme,
    String? helpText,
    DateTimeRange? initialValue,
  }) {
    return showMonthRangePicker(
      context: context,
      headerTitle: helpText == null ? null : Text(helpText),
      initialRangeDate: initialValue?.start,
      endRangeDate: initialValue?.end,
    ).then((value) {
      if (value == null || value.isEmpty) {
        return null;
      } else {
        return DateTimeRange(start: value.first, end: value.last);
      }
    });
  }
}

// class YearRangeType implements RangeType {
//   const YearRangeType();
//   @override
//   String displayFormat(DateTimeRange range) {
//     return 'MM/yyyy';
//   }

//   @override
//   Future<DateTimeRange?> showDialog(BuildContext context,ColorScheme colorScheme) {}
// }

// class TimeRangeType implements RangeType {
//   const TimeRangeType();
//   @override
//   String displayFormat(DateTimeRange range) {
//     return 'MM/yyyy';
//   }

//   @override
//   Future<DateTimeRange?> showDialog(BuildContext context) {}
// }

class DateRangeFormField<T extends DateTime> extends StatefulWidget {
  const DateRangeFormField({
    super.key,
    this.label,
    this.icon,
    this.textStyle,
    this.enabled = true,
    this.initialValue,
    required this.rangeType,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.helpText,
    this.controller,
    this.focusNode,
    this.allowClear = false,
  });
  final Widget? label;
  final RangeType<T> rangeType;
  final Widget? icon;
  final String? helpText;
  final TextStyle? textStyle;
  final DateTimeRange<T>? initialValue;
  final bool enabled;
  final bool allowClear;
  final FocusNode? focusNode;
  final Function(DateTimeRange<T>? range)? onChanged;
  final Function(DateTimeRange<T>? range)? onSaved;
  final String? Function(DateTimeRange<T>? range)? validator;
  final DateRangeEditingController<T>? controller;
  @override
  State<DateRangeFormField> createState() => _DateRangeFormFieldState<T>();
}

class _DateRangeFormFieldState<T extends DateTime>
    extends State<DateRangeFormField<T>> {
  late final TextEditingController _controller;
  late DateTimeRange<T>? _dateRange = widget.initialValue;
  @override
  void initState() {
    _controller = TextEditingController(text: _daterangeFormat());
    widget.controller?.addListener(() {
      setState(() {
        _dateRange = widget.controller?.value;
        _controller.text = _daterangeFormat();
      });
    });
    super.initState();
  }

  String _daterangeFormat() {
    if (_dateRange == null) {
      return '';
    }
    return widget.rangeType.displayFormat(_dateRange!);
  }

  void _openDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    widget.rangeType
        .showDialog(
          context: context,
          colorScheme: colorScheme,
          initialValue: _dateRange,
          helpText: widget.helpText,
        )
        .then((DateTimeRange<T>? range) {
          setState(() {
            _dateRange = range;
            _controller.text = _daterangeFormat();
            if (widget.onChanged != null) {
              widget.onChanged!(_dateRange);
            }
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      focusNode: widget.focusNode,
      readOnly: true,
      style: widget.textStyle,
      onSaved: widget.onSaved == null
          ? null
          : (value) => widget.onSaved!(_dateRange),
      validator: widget.validator == null
          ? null
          : (value) => widget.validator!(_dateRange),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(5),
        suffix: widget.allowClear && _dateRange != null
            ? IconButton(
                iconSize: 24,
                onPressed: () {
                  setState(() {
                    _controller.text = '';
                    _dateRange = null;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(_dateRange);
                  }
                },
                icon: const Icon(Icons.close),
              )
            : null,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: widget.enabled ? colorScheme.outline : Colors.grey,
          ),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: widget.enabled ? colorScheme.outline : Colors.grey,
          ),
        ),
        label: widget.label,
        icon: widget.icon,
      ),
      controller: _controller,
      onTap: () {
        if (!widget.enabled) return;
        _openDialog();
      },
    );
  }
}

class DateRangeEditingController<T extends DateTime>
    extends ValueNotifier<DateTimeRange<T>?> {
  DateRangeEditingController(super.value);

  void clear() {
    value = null;
    notifyListeners();
  }
}
