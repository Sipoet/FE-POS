import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/image_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class ImageFormField extends StatefulWidget {
  final String? Function(List? models)? validator;
  final int maxFiles;
  final void Function(List<ImageModel>)? onChanged;
  const ImageFormField({
    super.key,
    this.validator,
    this.onChanged,
    this.maxFiles = 1,
  });

  @override
  State<ImageFormField> createState() => _ImageFormFieldState();
}

class _ImageFormFieldState extends State<ImageFormField> {
  late final Flash flash;
  List<ImageModel> images = [];
  @override
  void initState() {
    flash = Flash();
    super.initState();
  }

  bool get allowMultiple => widget.maxFiles > 1;
  @override
  Widget build(BuildContext context) {
    return FormField(
      validator: widget.validator,
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
      state.validate();
      widget.onChanged?.call(newImages);
    });
  }
}
