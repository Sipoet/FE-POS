import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';

class DateRangeFormField extends StatefulWidget {
  const DateRangeFormField({
    super.key,
    this.label,
    this.icon,
    this.textStyle,
    this.enabled = true,
    this.initialDateRange,
    this.datePickerOnly = false,
    this.onChanged,
    this.helpText,
    this.controller,
    this.focusNode,
    this.canRemove = false,
  });
  final Widget? label;
  final Widget? icon;
  final String? helpText;
  final TextStyle? textStyle;
  final DateTimeRange? initialDateRange;
  final bool enabled;
  final bool canRemove;
  final bool datePickerOnly;
  final FocusNode? focusNode;
  final Function(DateTimeRange? range)? onChanged;
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
    var formater = DateFormat('dd/MM/y');
    if (widget.datePickerOnly) {
      return "${formater.format(_dateRange!.start)} - ${formater.format(_dateRange!.end)}";
    }
    if (_isSameDay(_dateRange!.start, _dateRange!.end)) {
      var hourFormat = DateFormat('HH:mm');
      return "${formater.format(_dateRange!.start)} ${hourFormat.format(_dateRange!.start)} - ${hourFormat.format(_dateRange!.end)}";
    } else {
      final formater = DateFormat('dd/MM/y HH:mm');
      return "${formater.format(_dateRange!.start)} - ${formater.format(_dateRange!.end)}";
    }
  }

  bool _isSameDay(DateTime start, DateTime end) {
    return start.day == end.day &&
        start.month == end.month &&
        start.year == end.year;
  }

  final maxDate = DateTime(99999, 12, 31, 23, 59, 59, 59);
  final minDate = DateTime(1900);
  void _openDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.datePickerOnly) {
      showNativePicker(colorScheme);
    } else {
      showBoardPicker(colorScheme);
    }
  }

  void showNativePicker(ColorScheme colorScheme) {
    showDateRangePicker(
            context: context,
            locale: const Locale('id', 'ID'),
            fieldStartHintText: 'Mulai',
            fieldEndHintText: 'Akhir',
            initialDateRange: _dateRange,
            currentDate: DateTime.now(),
            firstDate: DateTime(1900),
            useRootNavigator: false,
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            lastDate: maxDate)
        .then(
      (pickedDateRange) {
        if (pickedDateRange == null) {
          return;
        }
        setState(() {
          _dateRange = pickedDateRange;

          _controller.text = _daterangeFormat();
          if (widget.onChanged != null) {
            widget.onChanged!(_dateRange);
          }
        });
        return;
      },
    );
  }

  void showBoardPicker(ColorScheme colorscheme) {
    showBoardDateTimeMultiPicker(
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
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      minimumDate: minDate,
      maximumDate: maxDate,
      pickerType: widget.datePickerOnly
          ? DateTimePickerType.date
          : DateTimePickerType.datetime,
      breakpoint: 1000,
    ).then((dateTimeRange) {
      setState(() {
        if (dateTimeRange != null) {
          _dateRange = DateTimeRange(
              start: dateTimeRange.start.toLocal(),
              end: dateTimeRange.end.toLocal());
        }
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
    return Stack(children: [
      TextFormField(
        focusNode: widget.focusNode,
        readOnly: true,
        style: widget.textStyle,
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    width: 2,
                    color: widget.enabled ? colorScheme.outline : Colors.grey)),
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    width: 2,
                    color: widget.enabled ? colorScheme.outline : Colors.grey)),
            label: widget.label,
            icon: widget.icon),
        controller: _controller,
        onTap: () {
          if (!widget.enabled) return;
          _openDialog();
        },
      ),
      Visibility(
          visible: widget.canRemove && _dateRange != null,
          child: Positioned(
            top: 1,
            right: 5,
            child: IconButton(
                iconSize: 30,
                onPressed: () {
                  setState(() {
                    _controller.text = '';
                    _dateRange = null;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(_dateRange);
                  }
                },
                icon: const Icon(Icons.close)),
          )),
    ]);
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
