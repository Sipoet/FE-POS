import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/image_model.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class MultipleImageFormField extends StatefulWidget {
  final String? Function(List<ImageModel>? models)? validator;
  final void Function(List<ImageModel>)? onChanged;
  final List<ImageModel>? initialValue;
  final double width;
  final double height;
  const MultipleImageFormField({
    super.key,
    this.validator,
    this.onChanged,
    this.initialValue,
    required this.width,
    required this.height,
  });

  @override
  State<MultipleImageFormField> createState() => _MultipleImageFormFieldState();
}

class _MultipleImageFormFieldState extends State<MultipleImageFormField>
    with PlatformChecker {
  late final Flash flash;
  List<ImageModel> images = [];
  @override
  void initState() {
    flash = Flash();
    images = widget.initialValue ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<ImageModel>>(
      validator: widget.validator,
      initialValue: images,
      builder: (state) {
        return Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 5,
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
                images = [];
                for (final item in event.session.items) {
                  final reader = item.dataReader!;
                  if (reader.canProvide(Formats.jpeg)) {
                    reader.getFile(
                      Formats.jpeg,
                      (file) async {
                        final XFile xfile = XFile.fromData(
                          await file.readAll(),
                        );
                        images.add(
                          ImageModel(
                            file: xfile,
                            fileSize: await xfile.length(),
                            mimeType: 'image/jpeg',
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
                        final XFile xfile = XFile.fromData(
                          await file.readAll(),
                        );
                        images.add(
                          ImageModel(
                            file: xfile,
                            fileSize: await xfile.length(),
                            mimeType: 'image/png',
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
                        final XFile xfile = XFile.fromData(
                          await file.readAll(),
                        );
                        images.add(
                          ImageModel(
                            file: xfile,
                            fileSize: await xfile.length(),
                            mimeType: 'image/bmp',
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
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _pickFile(state),
                    child: Container(
                      width: widget.width,
                      height: state.hasError
                          ? widget.height - 50
                          : widget.height,
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
                  if (isAndroid() || isIOS() || isWeb())
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        onPressed: () async {
                          final picker = ImagePicker();
                          XFile? file = await picker.pickImage(source: .camera);
                          if (file == null) {
                            return;
                          }
                          final newImages = (state.value ?? [])
                            ..add(
                              ImageModel(
                                file: file,
                                fileSize: await file.length(),
                                filename: file.name,
                                mimeType: file.mimeType,
                              ),
                            );
                          imageChanged(state, newImages);
                        },
                        icon: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: .circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.black),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Icon(Icons.camera_alt_rounded),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              onDropEnded: (event) {
                imageChanged(state, images);
              },
            ),
            if (state.hasError)
              Text(state.errorText!, style: TextFormatter.errorStyle),
          ],
        );
      },
    );
  }

  void imageChanged(FormFieldState state, List<ImageModel> images) {
    state.didChange(images);
    if (state.validate()) {
      widget.onChanged?.call(images);
    }
  }

  void _pickFile(FormFieldState state) async {
    final picker = ImagePicker();
    List<XFile> files = await picker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }
    final newImages = await Future.wait(
      files.map<Future<ImageModel>>((XFile file) async {
        return ImageModel(
          file: file,
          fileSize: await file.length(),
          filename: file.name,
          mimeType: file.mimeType,
        );
      }).toList(),
    );
    setState(() {
      imageChanged(state, newImages);
    });
  }
}

class ImageFormField extends StatefulWidget {
  final String? Function(ImageModel? image)? validator;
  final ImageModel? initialValue;
  final double width;
  final double height;
  final void Function(ImageModel?)? onChanged;
  const ImageFormField({
    super.key,
    this.validator,
    required this.width,
    required this.height,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<ImageFormField> createState() => _ImageFormFieldState();
}

class _ImageFormFieldState extends State<ImageFormField> with PlatformChecker {
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
        replacement: Stack(
          children: [
            GestureDetector(
              onTap: () => _viewImage(image!),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  border: .all(),
                  color: Colors.grey.shade300,
                  borderRadius: .all(.circular(10)),
                  image: DecorationImage(
                    image: ResizeImage(
                      image ?? ImageModel(),
                      width: widget.width.toInt(),
                      height: widget.height.toInt(),
                    ),
                    fit: .contain,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                onPressed: () => setState(() {
                  image = null;
                  imageChanged(state, image);
                }),
                icon: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: .circular(15),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Icon(Icons.delete),
                ),
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          spacing: 5,
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
                        final XFile xfile = XFile.fromData(
                          await file.readAll(),
                        );
                        image = ImageModel(
                          file: xfile,
                          fileSize: await xfile.length(),
                          mimeType: 'image/jpeg',
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
                        final XFile xfile = XFile.fromData(
                          await file.readAll(),
                        );
                        image = ImageModel(
                          file: xfile,
                          fileSize: await xfile.length(),
                          mimeType: 'image/png',
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
                        final XFile xfile = XFile.fromData(
                          await file.readAll(),
                        );
                        image = ImageModel(
                          file: xfile,
                          fileSize: await xfile.length(),
                          mimeType: 'image/bmp',
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
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _pickFile(state, .gallery),
                    child: Container(
                      width: widget.width,
                      height: state.hasError
                          ? widget.height - 50
                          : widget.height,
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
                  if (isAndroid() || isWeb() || isIOS())
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        iconSize: 30,
                        onPressed: () => _pickFile(state, .camera),
                        icon: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: .circle,
                            border: Border.all(color: Colors.black),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(Icons.camera_alt_rounded),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              onDropEnded: (event) {
                setState(() {
                  imageChanged(state, image);
                });
              },
            ),
            if (state.hasError)
              Text(state.errorText!, style: TextFormatter.errorStyle),
          ],
        ),
      ),
    );
  }

  void _viewImage(ImageModel selectedImage) {
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Image(image: selectedImage),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton.filled(
                  onPressed: () => navigator.pop(),
                  icon: Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickFile(
    FormFieldState<ImageModel> state,
    ImageSource imageSource,
  ) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: imageSource);
    if (file == null) {
      return;
    }
    final newImage = ImageModel(
      file: file,
      fileSize: await file.length(),
      filename: file.name,
      mimeType: file.mimeType,
    );
    setState(() {
      imageChanged(state, newImage);
    });
  }

  void imageChanged(FormFieldState state, ImageModel? newImage) {
    state.didChange(newImage);
    if (state.validate()) {
      image = newImage;
      widget.onChanged?.call(newImage);
    } else {
      image = null;
    }
  }
}
