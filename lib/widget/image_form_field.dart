import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/image_model.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:file_picker/file_picker.dart';

class MultipleImageFormField extends StatefulWidget {
  final String? Function(List<ImageModel>? models)? validator;
  final void Function(List<ImageModel>)? onChanged;
  final double width;
  final double height;
  final ChangeNotifier? notifier;
  final ValueCallBack<List<ImageModel>>? valueCallback;
  const MultipleImageFormField({
    super.key,
    this.validator,
    this.onChanged,
    this.notifier,
    this.valueCallback,
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
    images = widget.valueCallback?.call() ?? [];
    widget.notifier?.addListener(refreshValue);
    super.initState();
  }

  @override
  void dispose() {
    widget.notifier?.removeListener(refreshValue);
    super.dispose();
  }

  void refreshValue() {
    setState(() {
      // images = widget.valueCallback?.call() ?? images;
    });
  }

  Future<ImageModel> readImage(file, String mimeType) async {
    final XFile xfile = XFile.fromData(
      await file.readAll(),
      name: file.fileName,
      length: file.fileSize,
    );
    final filesize = file.fileSize ?? await xfile.length();
    final image = ImageModel(
      file: xfile,
      fileSize: filesize,
      mimeType: mimeType,
      filename: file.fileName,
    );
    images.add(image);
    loadedImageLength++;
    return image;
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
                tryCheck = 0;
                loadedImageLength = 0;
                for (final item in event.session.items) {
                  final reader = item.dataReader!;

                  if (reader.canProvide(Formats.jpeg)) {
                    reader.getFile(
                      Formats.jpeg,
                      (file) => readImage(file, 'image/jpeg'),
                      onError: (error) {
                        flash.show(Text('Error reading value $error'), .error);
                      },
                    );
                  } else if (reader.canProvide(Formats.png)) {
                    reader.getFile(
                      Formats.png,
                      (file) => readImage(file, 'image/png'),
                      onError: (error) {
                        flash.show(Text('Error reading value $error'), .error);
                      },
                    );
                  } else if (reader.canProvide(Formats.bmp)) {
                    reader.getFile(
                      Formats.bmp,
                      (file) => readImage(file, 'image/bmp'),
                      onError: (error) {
                        flash.show(Text('Error reading value $error'), .error);
                      },
                    );
                  } else {
                    flash.show(Text('not supported images/file'), .error);
                  }
                }
                return Future(() => onDropEnded(event, state));
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
                          images.add(
                            ImageModel(
                              file: file,
                              fileSize: await file.length(),
                              filename: file.name,
                              mimeType: file.mimeType,
                            ),
                          );
                          imageChanged(state);
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
                setState(() {
                  imageChanged(state);
                });
              },
            ),
            if (state.hasError)
              Text(state.errorText!, style: TextFormatter.errorStyle),
          ],
        );
      },
    );
  }

  int tryCheck = 0;
  int loadedImageLength = 0;
  Future onDropEnded(PerformDropEvent event, FormFieldState state) {
    if (loadedImageLength != event.session.items.length && tryCheck <= 10) {
      tryCheck++;
      return Future.delayed(Duration(microseconds: 200), () {
        return onDropEnded(event, state);
      });
    } else {
      return Future.value();
    }
  }

  void imageChanged(FormFieldState state) {
    state.didChange(images);
    if (state.validate()) {
      widget.onChanged?.call(images);
    }
  }

  void _pickFile(FormFieldState state) async {
    List<XFile> files;
    if (isWeb()) {
      FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'pilih gambar',
        type: .image,
        allowMultiple: true,
        withData: true,
      );
      files = result?.xFiles ?? [];
    } else {
      final picker = ImagePicker();
      files = await picker.pickMultiImage();
    }
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
    images.addAll(newImages);
    setState(() {
      imageChanged(state);
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
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Icon(Icons.delete),
                  ),
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
    XFile? file;
    if (isWeb()) {
      FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'pilih gambar',
        type: .image,
        allowMultiple: false,
        withData: true,
      );
      file = result?.xFiles.firstOrNull;
    } else {
      final picker = ImagePicker();
      file = await picker.pickImage(source: imageSource);
    }

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
