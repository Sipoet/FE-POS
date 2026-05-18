import 'package:collection/collection.dart';
import 'package:fe_pos/tool/image_model.dart';
import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  final void Function(ImageModel image)? onRemoved;
  final List<ImageModel> images;
  final double width;
  final double height;
  final bool allowClear;
  const ImageCarousel({
    super.key,
    required this.images,
    this.onRemoved,
    this.allowClear = false,
    this.width = 200,
    this.height = 200,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int activeIndex = 0;
  int leftIndex = 0;
  int rightIndex = 0;
  final int bulletCount = 3;
  List<ImageModel> get images =>
      widget.images.whereNot((e) => e.isDestroyed).toList();

  @override
  void initState() {
    rightIndex = [bulletCount, images.length].min;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return SizedBox();
    }
    return Stack(
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: .all(),
            color: Colors.grey.shade300,
            borderRadius: .all(.circular(10)),
            image: DecorationImage(image: images[activeIndex], fit: .contain),
          ),
        ),
        Visibility(
          visible: widget.allowClear,
          child: Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: () {
                final image = images[activeIndex];
                widget.onRemoved?.call(image);
                debugPrint('images: ${images.length}');
                final imageCount = images.length;
                if (rightIndex > imageCount) {
                  rightIndex = imageCount;
                  leftIndex = [rightIndex - bulletCount, 0].max;
                }
                if (activeIndex > imageCount - 1) {
                  activeIndex = imageCount - 1;
                }
              },
              icon: Icon(Icons.delete),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          width: widget.width,
          child: Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  if (activeIndex == 0) {
                    return;
                  }
                  activeIndex--;
                  if (leftIndex - 1 < activeIndex) {
                    return;
                  }
                  leftIndex = [leftIndex - 1, 0].max;
                  rightIndex = [leftIndex + bulletCount, images.length - 1].min;
                }),
                icon: Icon(Icons.chevron_left_sharp),
              ),
              ...images
                  .sublist(leftIndex, rightIndex)
                  .map<Widget>(
                    (image) => SizedBox(
                      height: 15,
                      width: 15,
                      child: OutlinedButton(
                        onPressed: () {
                          int index = images.indexOf(image);
                          if (activeIndex == index) {
                            return;
                          }
                          setState(() {
                            activeIndex = index;
                          });
                        },

                        style: OutlinedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(0),
                          side: const BorderSide(width: 1, color: Colors.black),
                          backgroundColor: activeIndex == images.indexOf(image)
                              ? Colors.black
                              : Colors.white,
                        ),
                        child: SizedBox(),
                      ),
                    ),
                  ),
              IconButton(
                onPressed: () => setState(() {
                  if (activeIndex == images.length - 1) {
                    return;
                  }
                  activeIndex++;
                  if (activeIndex < rightIndex) {
                    return;
                  }
                  rightIndex = [rightIndex + 1, images.length].min;
                  leftIndex = [rightIndex - bulletCount, 0].max;
                }),
                icon: Icon(Icons.chevron_right_sharp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
