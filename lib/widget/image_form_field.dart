import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/image_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class MultipleImageFormField extends StatefulWidget {
  final String? Function(List<ImageModel>? models)? validator;
  final int maxFiles;
  final void Function(List<ImageModel>)? onChanged;
  final List<ImageModel>? initialValue;
  const MultipleImageFormField({
    super.key,
    this.validator,
    this.onChanged,
    this.initialValue,
    this.maxFiles = 1,
  });

  @override
  State<MultipleImageFormField> createState() => _MultipleImageFormFieldState();
}

class _MultipleImageFormFieldState extends State<MultipleImageFormField> {
  late final Flash flash;
  List<ImageModel> images = [];
  @override
  void initState() {
    flash = Flash();
    images = widget.initialValue ?? [];
    super.initState();
  }

  bool get allowMultiple => widget.maxFiles > 1;
  @override
  Widget build(BuildContext context) {
    return FormField<List<ImageModel>>(
      validator: widget.validator,
      initialValue: images,
      builder: (state) {
        return DropRegion(
          formats: [Formats.jpeg, Formats.png, Formats.bmp],
          onDropOver: (event) {
            if (event.session.allowedOperations.contains(DropOperation.copy)) {
              return DropOperation.copy;
            } else {
              return DropOperation.none;
            }
          },
          onPerformDrop: (event) {
            images = [];
            if (event.session.items.length > widget.maxFiles) {
              setState(() {});
            }

            for (final item in event.session.items) {
              final reader = item.dataReader!;
              if (reader.canProvide(Formats.jpeg)) {
                reader.getFile(
                  Formats.jpeg,
                  (file) async {
                    final bytes = await file.readAll();
                    images.add(
                      ImageModel(
                        bytes: bytes,
                        contentType: .jpg,
                        filename: file.fileName,
                      ),
                    );
                  },
                  onError: (error) {
                    flash.show(Text('Error reading value $error'), .error);
                  },
                );
              } else if (reader.canProvide(Formats.png)) {
                reader.getFile(
                  Formats.png,
                  (file) async {
                    final bytes = await file.readAll();
                    images.add(
                      ImageModel(
                        bytes: bytes,
                        contentType: .png,
                        filename: file.fileName,
                      ),
                    );
                  },
                  onError: (error) {
                    flash.show(Text('Error reading value $error'), .error);
                  },
                );
              } else if (reader.canProvide(Formats.bmp)) {
                reader.getFile(
                  Formats.bmp,
                  (file) async {
                    final bytes = await file.readAll();
                    images.add(
                      ImageModel(
                        bytes: bytes,
                        contentType: .bmp,
                        filename: file.fileName,
                      ),
                    );
                  },
                  onError: (error) {
                    flash.show(Text('Error reading value $error'), .error);
                  },
                );
              } else {
                flash.show(Text('not supported images/file'), .error);
              }
            }
            return Future.value();
          },
          child: GestureDetector(
            onTap: () => _pickFile(state),
            child: Container(
              color: Colors.grey.shade200,
              child: Placeholder(
                strokeWidth: 1,
                color: Colors.black45,
                child: Center(
                  child: Text(
                    'Letakkan atau Pilih Gambar',
                    style: DefaultResponse.labelStyle,
                    textAlign: .center,
                  ),
                ),
              ),
            ),
          ),

          onDropEnded: (event) {
            state.validate();
            widget.onChanged?.call(images);
          },
        );
      },
    );
  }

  void _pickFile(FormFieldState state) async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Pilih Gambar',
      type: .image,
      withData: true,
      allowMultiple: allowMultiple,
    );
    if (result == null) {
      return;
    }

    setState(() {
      final newImages = result.files.map<ImageModel>((file) {
        HttpContentType? contentType;
        try {
          contentType = HttpContentType.fromString(file.xFile.mimeType);
        } catch (e) {
          debugPrint(e.toString());
        }
        return ImageModel(
          bytes: file.bytes,
          filename: file.name,
          contentType: contentType,
        );
      }).toList();
      state.didChange(newImages);
      state.validate();
      widget.onChanged?.call(newImages);
    });
  }
}

class ImageFormField extends StatefulWidget {
  final String? Function(ImageModel? image)? validator;
  final ImageModel? initialValue;
  final double? width;
  final double? height;
  final void Function(ImageModel?)? onChanged;
  const ImageFormField({
    super.key,
    this.validator,
    this.width,
    this.height,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<ImageFormField> createState() => _ImageFormFieldState();
}

class _ImageFormFieldState extends State<ImageFormField> {
  late final Flash flash;
  ImageModel? image;
  @override
  void initState() {
    flash = Flash();
    image = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<ImageModel>(
      validator: widget.validator,
      initialValue: image,
      builder: (state) => Visibility(
        visible: image == null,
        replacement: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  border: .all(),
                  color: Colors.grey.shade300,
                  borderRadius: .all(.circular(10)),
                  image: DecorationImage(
                    image: ResizeImage(
                      image ?? ImageModel(),
                      width:
                          widget.width?.toInt() ??
                          image?.size?.width.toInt() ??
                          0,
                      height:
                          widget.height?.toInt() ??
                          image?.size?.height.toInt() ??
                          0,
                    ),
                    fit: .contain,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  onPressed: () => setState(() {
                    image = null;
                    state.didChange(image);
                    state.validate();
                    widget.onChanged?.call(image);
                  }),
                  icon: Icon(Icons.delete),
                ),
              ),
            ],
          ),
        ),
        child: Column(
          children: [
            DropRegion(
              formats: [Formats.jpeg, Formats.png, Formats.bmp],
              onDropOver: (event) {
                if (event.session.allowedOperations.contains(
                  DropOperation.copy,
                )) {
                  return DropOperation.copy;
                } else {
                  return DropOperation.none;
                }
              },
              onPerformDrop: (event) {
                if (event.session.items.length > 1) {
                  setState(() {});
                }

                for (final item in event.session.items) {
                  final reader = item.dataReader!;
                  if (reader.canProvide(Formats.jpeg)) {
                    reader.getFile(
                      Formats.jpeg,
                      (file) async {
                        final bytes = await file.readAll();
                        image = ImageModel(
                          bytes: bytes,
                          contentType: .jpg,
                          filename: file.fileName,
                        );
                      },
                      onError: (error) {
                        flash.show(Text('Error reading value $error'), .error);
                      },
                    );
                  } else if (reader.canProvide(Formats.png)) {
                    reader.getFile(
                      Formats.png,
                      (file) async {
                        final bytes = await file.readAll();
                        image = ImageModel(
                          bytes: bytes,
                          contentType: .png,
                          filename: file.fileName,
                        );
                      },
                      onError: (error) {
                        flash.show(Text('Error reading value $error'), .error);
                      },
                    );
                  } else if (reader.canProvide(Formats.bmp)) {
                    reader.getFile(
                      Formats.bmp,
                      (file) async {
                        final bytes = await file.readAll();
                        image = ImageModel(
                          bytes: bytes,
                          contentType: .bmp,
                          filename: file.fileName,
                        );
                      },
                      onError: (error) {
                        flash.show(Text('Error reading value $error'), .error);
                      },
                    );
                  } else {
                    flash.show(Text('not supported images/file'), .error);
                  }
                }
                return Future.value();
              },
              child: GestureDetector(
                onTap: () => _pickFile(state),
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  color: Colors.grey.shade200,
                  child: Placeholder(
                    strokeWidth: 1,
                    color: Colors.black45,
                    child: Center(
                      child: Text(
                        'Letakkan atau Pilih Gambar',
                        style: DefaultResponse.labelStyle,
                        textAlign: .center,
                      ),
                    ),
                  ),
                ),
              ),

              onDropEnded: (event) {
                setState(() {
                  state.didChange(image);
                  state.validate();
                  widget.onChanged?.call(image);
                });
              },
            ),
            if (state.hasError)
              Text(
                state.errorText!,
                style: TextStyle(color: Colors.red.shade300),
              ),
          ],
        ),
      ),
    );
  }

  void _pickFile(FormFieldState<ImageModel> state) async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Pilih Gambar',
      type: .image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null) {
      return;
    }

    setState(() {
      final file = result.files.firstOrNull;
      if (file == null) {
        return;
      }

      HttpContentType? contentType;
      try {
        contentType = HttpContentType.fromString(file.xFile.mimeType);
      } catch (e) {
        debugPrint(e.toString());
      }
      image = ImageModel(
        bytes: file.bytes,
        filename: file.name,
        contentType: contentType,
      );
      state.didChange(image);
      state.validate();
      widget.onChanged?.call(image);
    });
  }
}
