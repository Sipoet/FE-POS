import 'package:collection/collection.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fe_pos/tool/file_attachment.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class FileFormField extends StatefulWidget {
  final List<FileAttachment>? initialFiles;
  final void Function(List<FileAttachment>? files)? onChanged;
  final List<FormFileType> fileTypes;
  final String? Function(List<FileAttachment>? files)? validator;
  const FileFormField({
    super.key,
    required this.fileTypes,
    this.initialFiles,
    this.onChanged,
    this.validator,
  });

  @override
  State<FileFormField> createState() => _FileFormFieldState();
}

class _FileFormFieldState extends State<FileFormField> with PlatformChecker {
  List<FileAttachment> files = [];
  late final Flash flash;
  final _scrollController = ScrollController();
  int tryCheck = 0;
  int loadedImageLength = 0;
  @override
  void initState() {
    flash = Flash();
    files = widget.initialFiles ?? [];
    super.initState();
  }

  void _pickFile(FormFieldState state, {bool pickCamera = false}) async {
    List<FileAttachment> fileAdded;
    if (pickCamera &&
        widget.fileTypes.contains(FormFileType.image) &&
        isMobile()) {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: .camera);
      if (file == null) {
        return;
      }
      fileAdded = [FileAttachmentClass().fromFile(file)];
    } else {
      FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'pilih file',
        type: widget.fileTypes.length == 1
            ? widget.fileTypes.first.pickerFileType
            : .custom,
        allowedExtensions: widget.fileTypes
            .map<List<String>>((e) => e.allowedExtension)
            .flattenedToList,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) {
        return;
      }
      fileAdded = result.xFiles
          .map<FileAttachment>((file) => FileAttachmentClass().fromFile(file))
          .toList();
    }

    setState(() {
      files.addAll(fileAdded);
    });

    state.didChange(files);
    if (state.validate()) {
      state.save();
    }
  }

  Future<FileAttachment> readFile(file, DataFormat format) async {
    final addedfile = await FileAttachmentClass().fromDroppedFile(file);
    setState(() {
      files.add(addedfile);
    });
    loadedImageLength++;
    return addedfile;
  }

  List<DataFormat> get allowedFormats =>
      widget.fileTypes.map<List<DataFormat>>((e) => e.formats).flattenedToList;

  @override
  Widget build(BuildContext context) {
    return FormField<List<FileAttachment>>(
      onSaved: widget.onChanged,
      validator: widget.validator,
      builder: (state) {
        return Column(
          spacing: 10,
          children: [
            DropRegion(
              formats: allowedFormats,
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
                  for (final format in allowedFormats) {
                    if (reader.canProvide(format)) {
                      reader.getFile(
                        format as FileFormat,
                        (file) => readFile(file, format),
                        onError: (error) {
                          flash.show(
                            Text('Error reading value $error'),
                            .error,
                          );
                        },
                      );
                      break;
                    }
                  }
                }
                return Future(() => onDropEnded(event, state));
              },
              child: ElevatedButton(
                onPressed: () => _pickFile(state),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 20,
                  ),
                  child: Column(
                    spacing: 5,
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .center,
                    children: [
                      if (widget.fileTypes.contains(FormFileType.image) &&
                          isMobile())
                        IconButton(
                          iconSize: 30,
                          onPressed: () => _pickFile(state, pickCamera: true),
                          icon: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: .circle,
                              border: Border.all(color: Colors.black),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(Icons.photo_camera),
                            ),
                          ),
                        ),
                      Icon(Icons.file_upload, size: 30),
                      Text('Tambah File', style: TextStyle(fontSize: 18)),
                      Text(
                        'Gambar(png,jpg,webp) atau dokumen(pdf,docx)',
                        // style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Visibility(
              visible: files.isNotEmpty,
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 8,
                controller: _scrollController,
                child: Container(
                  height: 200,
                  width: 350,
                  decoration: BoxDecoration(
                    border: .all(color: Colors.grey.shade500),
                  ),
                  padding: const .all(8),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: .horizontal,
                      itemCount: files.length,
                      separatorBuilder: (context, index) {
                        final file = files[index];
                        if (file.isDestroyed) {
                          return SizedBox.shrink();
                        }
                        return const SizedBox(width: 5);
                      },
                      itemBuilder: (context, index) {
                        final file = files[index];
                        if (file.isDestroyed) {
                          return SizedBox.shrink();
                        }
                        return thumbnailFile(files[index], context);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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

  Widget thumbnailFile(FileAttachment file, BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            InkWell(
              onTap: () => file.showPreview(context),
              child: file.thumbnail(width: 150, height: 150),
            ),
            Positioned(
              top: 0,
              right: 5,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    if (file.isAttached) {
                      file.flagDestroy();
                    } else {
                      files.remove(file);
                    }
                  });
                },
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
        Text(file.filename ?? '', overflow: .clip),
      ],
    );
  }
}

enum FormFileType {
  document,
  image,
  video,
  audio;

  FileType get pickerFileType {
    switch (this) {
      case document:
        return .custom;
      case image:
        return .image;
      case video:
        return .video;
      case audio:
        return .audio;
    }
  }

  List<String> get allowedExtension {
    switch (this) {
      case document:
        return ['pdf', 'docx'];
      case image:
        return ['png', 'jpg', 'webp', 'jpeg', 'bmp', 'svg'];
      case video:
        return ['mp4', 'webm', 'm4a'];
      case audio:
        return ['mp3', 'wav'];
    }
  }

  List<DataFormat> get formats {
    switch (this) {
      case document:
        return [Formats.pdf, Formats.docx];
      case image:
        return [
          Formats.png,
          Formats.jpeg,
          Formats.webp,
          Formats.bmp,
          Formats.svg,
        ];
      case video:
        return [Formats.mp4, Formats.webm, Formats.mpeg];
      case audio:
        return [Formats.mp3, Formats.wav];
    }
  }
}
