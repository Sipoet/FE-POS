import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

abstract class RangeType {
  const RangeType();
  String displayFormat(DateTimeRange range);
  Future<DateTimeRange?> showDialog(
      {required BuildContext context,
      required ColorScheme colorScheme,
      String? helpText,
      DateTimeRange? initialDateRange});
}

class DateTimeRangeType implements RangeType {
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
  Future<DateTimeRange?> showDialog(
      {required BuildContext context,
      required ColorScheme colorScheme,
      String? helpText,
      DateTimeRange? initialDateRange}) {
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
              locale: 'id')),
      startDate: initialDateRange?.start,
      endDate: initialDateRange?.end,
      showDragHandle: false,
      enableDrag: false,
      pickerType: DateTimePickerType.datetime,
    ).then((dateTimeRange) {
      if (dateTimeRange != null) {
        return DateTimeRange(
            start: dateTimeRange.start.toLocal(),
            end: dateTimeRange.end.toLocal());
      }
      return null;
    });
  }
}

class DateRangeType implements RangeType {
  const DateRangeType();
  @override
  String displayFormat(DateTimeRange range) {
    final formater = DateFormat('dd/MM/y');
    return "${formater.format(range.start)} - ${formater.format(range.end)}";
  }

  @override
  Future<DateTimeRange?> showDialog(
      {required BuildContext context,
      required ColorScheme colorScheme,
      String? helpText,
      DateTimeRange? initialDateRange}) {
    return showDateRangePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      fieldStartHintText: 'Mulai',
      fieldEndHintText: 'Akhir',
      initialDateRange: initialDateRange,
      currentDate: DateTime.now(),
      firstDate: DateTime(1000),
      lastDate: DateTime.now().add(Duration(days: 36500)),
      // useRootNavigator: false,
      initialEntryMode: DatePickerEntryMode.calendar,
    );
  }
}

class MonthRangeType implements RangeType {
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
  Future<DateTimeRange?> showDialog(
      {required BuildContext context,
      required ColorScheme colorScheme,
      String? helpText,
      DateTimeRange? initialDateRange}) {
    return showMonthRangePicker(
            context: context,
            headerTitle: helpText == null ? null : Text(helpText),
            initialRangeDate: initialDateRange?.start,
            endRangeDate: initialDateRange?.end)
        .then((value) {
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

class DateRangeFormField extends StatefulWidget {
  const DateRangeFormField({
    super.key,
    this.label,
    this.icon,
    this.textStyle,
    this.enabled = true,
    this.initialDateRange,
    this.rangeType = const DateTimeRangeType(),
    this.validator,
    this.onSaved,
    this.onChanged,
    this.helpText,
    this.controller,
    this.focusNode,
    this.allowClear = false,
  });
  final Widget? label;
  final RangeType rangeType;
  final Widget? icon;
  final String? helpText;
  final TextStyle? textStyle;
  final DateTimeRange? initialDateRange;
  final bool enabled;
  final bool allowClear;
  final FocusNode? focusNode;
  final Function(DateTimeRange? range)? onChanged;
  final Function(DateTimeRange? range)? onSaved;
  final String? Function(DateTimeRange? range)? validator;
  final PickerController? controller;
  @override
  State<DateRangeFormField> createState() => _DateRangeFormFieldState();
}

class _DateRangeFormFieldState extends State<DateRangeFormField> {
  late final TextEditingController _controller;
  late DateTimeRange? _dateRange = widget.initialDateRange;
  @override
  void initState() {
    _controller = TextEditingController(text: _daterangeFormat());
    widget.controller?.addListener(() {
      setState(() {
        _dateRange = widget.controller?.range ?? _dateRange;
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
            initialDateRange: _dateRange,
            helpText: widget.helpText)
        .then((DateTimeRange? range) {
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
          suffix: widget.allowClear
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
                  color: widget.enabled ? colorScheme.outline : Colors.grey)),
          border: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 1,
                  color: widget.enabled ? colorScheme.outline : Colors.grey)),
          label: widget.label,
          icon: widget.icon),
      controller: _controller,
      onTap: () {
        if (!widget.enabled) return;
        _openDialog();
      },
    );
  }
}

class PickerController extends ChangeNotifier {
  DateTimeRange range;
  PickerController(this.range);

  void changeDate(DateTimeRange newRange) {
    range = newRange;
    notifyListeners();
  }
}
