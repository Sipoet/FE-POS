import 'dart:async';
import 'package:flutter/material.dart';

typedef ViewBuilder<T> = Widget Function({
  required T object,
  bool isValid,
});
typedef StringConverter<T> = String Function(T object);
typedef OptionBuilder<T> = FutureOr<Iterable<T>> Function(
    TextEditingValue textEditingValue);

class TagSelectField<T extends Object> extends StatefulWidget {
  final List<TagData<T>>? initialValue;
  final String? Function(T object)? singleTagValidator;
  final String? Function(List<T>)? validator;
  final void Function(String word, TagController controller)? onDetectSeparator;
  final void Function(List<T> data)? onSubmitted;
  final TagController<T>? controller;
  final TagData<T> Function(String word) wordToTagData;
  final List<String> textSeparators;
  final ViewBuilder<TagData<T>>? tagViewBuilder;
  final OptionBuilder<TagData<T>>? optionBuilder;
  final StringConverter<TagData<T>>? displayStringForOption;
  final Widget? label;
  final double optionsMaxHeight;
  const TagSelectField(
      {super.key,
      this.controller,
      this.label,
      this.optionsMaxHeight = 200,
      required this.wordToTagData,
      this.displayStringForOption,
      this.optionBuilder,
      this.tagViewBuilder,
      this.textSeparators = const [' '],
      this.onDetectSeparator,
      this.onSubmitted,
      this.validator,
      this.singleTagValidator,
      this.initialValue});

  @override
  State<TagSelectField<T>> createState() => _TagSelectFieldState<T>();
}

class _TagSelectFieldState<T extends Object> extends State<TagSelectField<T>> {
  final _textGlobalKey = GlobalKey();
  late final TagController<T> _controller;
  late final ViewBuilder<TagData<T>> _tagViewBuilder;
  late final StringConverter<TagData<T>> displayStringForOption;
  late final OptionBuilder<TagData<T>> optionBuilder;
  double? _textFieldWidth;
  @override
  void initState() {
    if (widget.controller != null && widget.initialValue != null) {
      throw 'choose either controller or initialValue. can\'t use both';
    }
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TagController<T>(tags: widget.initialValue ?? []);
    }
    _controller.addListener(() {
      setState(() {
        _controller;
      });
    });
    _tagViewBuilder = widget.tagViewBuilder ?? _defaultPillWidget;
    displayStringForOption =
        widget.displayStringForOption ?? (TagData<T> data) => data.searchText;
    optionBuilder = widget.optionBuilder ?? (_) => Iterable<TagData<T>>.empty();
    super.initState();
  }

  Widget _defaultPillWidget({required TagData<T> object, bool isValid = true}) {
    return DefaultPillWidget(
      text: object.label,
      description: object.searchText,
      onRemove: () => setState(() {
        _controller.removeTag(object);
      }),
    );
  }

  void analyzeWord(String words) {
    // if (words.isEmpty && _controller.isTagNotEmpty) {
    //   _controller.removeTag(_controller.tags.last);
    //   return;
    // }
    final pattern = RegExp(
      "[${widget.textSeparators.map((e) => "\\$e").join()}]",
      caseSensitive: false,
    );
    if (words.contains(pattern)) {
      if (widget.onDetectSeparator != null) {
        widget.onDetectSeparator!(words.replaceAll(pattern, ''), _controller);
      } else if (T is String) {
        _controller.addTag(TagData(value: words, label: words) as TagData<T>);
      } else {
        final clearWord = words.replaceAll(pattern, '');
        final tag = widget.wordToTagData(clearWord);
        addIfValid(tag);
      }
    }
// widget.tagSeparator,
  }

  void addIfValid(TagData<T> data) {
    if (widget.singleTagValidator == null ||
        widget.singleTagValidator!(data.value) == null) {
      setState(() {
        _controller.addTag(data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_textGlobalKey.currentContext != null) {
        final RenderBox renderBox =
            _textGlobalKey.currentContext!.findRenderObject() as RenderBox;
        if (_textFieldWidth != renderBox.size.width) {
          setState(() {
            _textFieldWidth = renderBox.size.width;
          });
        }
        debugPrint('width ${_textFieldWidth.toString()}');
      }
    });
    final colorScheme = Theme.of(context).colorScheme;
    return Autocomplete<TagData<T>>(
      optionsBuilder: (editValue) {
        final newValue = editValue.copyWith(text: editValue.text.trimLeft());
        return optionBuilder(newValue);
      },
      displayStringForOption: displayStringForOption,
      onSelected: (data) {
        addIfValid(data);
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 3.0,
          child: Container(
            width: _textFieldWidth,
            constraints: BoxConstraints(maxHeight: widget.optionsMaxHeight),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final option = options.elementAt(index);
                bool isHighlight =
                    AutocompleteHighlightedOption.of(context) == index;

                return GestureDetector(
                  onTap: () {
                    onSelected(option);
                  },
                  child: ListTile(
                    tileColor: isHighlight ? colorScheme.outlineVariant : null,
                    title: Text(
                      option.searchText,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        _controller.controller = textEditingController;
        textEditingController.text = ' ';
        return TextFormField(
          key: _textGlobalKey,
          focusNode: focusNode,
          onChanged: analyzeWord,
          onEditingComplete: () {
            onFieldSubmitted();
          },
          controller: textEditingController,
          validator: (_) => widget.validator == null
              ? null
              : widget.validator!(_controller.values),
          decoration: InputDecoration(
            label: widget.label,
            border: OutlineInputBorder(),
            prefixIcon: SingleChildScrollView(
              // controller: inputFieldValues.tagScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ..._controller.tags.map<Widget>(
                    (e) => _tagViewBuilder(object: e, isValid: true)),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class TagController<T> extends ChangeNotifier {
  List<TagData<T>> _tags = [];
  late TextEditingController controller;
  TagController({List<TagData<T>>? tags}) : _tags = tags ?? [];

  void clear() {
    _tags.clear();
    notifyListeners();
  }

  bool get isTagEmpty => _tags.isEmpty;
  bool get isTagNotEmpty => _tags.isNotEmpty;

  List<TagData<T>> get tags => _tags;
  List<T> get values => _tags.map((e) => e.value).toList();

  void removeTag(TagData<T> object) {
    _tags.remove(object);
    notifyListeners();
  }

  void addTag(TagData<T> object) {
    _tags.add(object);
    notifyListeners();
  }
}

class DefaultPillWidget extends StatelessWidget {
  final String text;
  final String? description;
  final void Function()? onRemove;
  const DefaultPillWidget({
    super.key,
    this.description,
    this.text = '',
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: description,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(5.0),
          ),
          color: colorScheme.primaryContainer,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 4.0),
            InkWell(
              onTap: onRemove,
              child: const Icon(
                Icons.cancel,
                size: 14.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TagData<T> {
  String label;
  String? _searchText;
  Map<String, dynamic> meta = {};
  T value;
  TagData(
      {this.label = '',
      required this.value,
      String? searchText,
      Map<String, dynamic>? meta})
      : meta = meta ?? {},
        _searchText = searchText;

  String get searchText => _searchText ?? label;
  set searchText(String? value) => _searchText = value;
  bool contains(String word) {
    return "${searchText.toLowerCase()} ${label.toLowerCase()}"
        .contains(word.toLowerCase());
  }
}
