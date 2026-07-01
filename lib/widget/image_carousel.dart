import 'package:collection/collection.dart';
import 'package:fe_pos/tool/image_model.dart';
import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  final void Function(ImageModel image)? onRemoved;
  final ImageCarouselController controller;
  final double width;
  final double height;
  final bool allowClear;
  const ImageCarousel({
    super.key,
    required this.controller,
    this.onRemoved,
    this.allowClear = false,
    this.width = 200,
    this.height = 200,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  ImageCarouselController get controller => widget.controller;

  @override
  void initState() {
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.images.isEmpty) {
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
            image: DecorationImage(
              image: ResizeImage(
                controller.activeImage,
                width: widget.width.toInt(),
                height: widget.height.toInt(),
              ),
              fit: .contain,
            ),
          ),
        ),
        Visibility(
          visible: widget.allowClear,
          child: Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: () {
                setState(() {
                  final image = controller.activeImage;
                  widget.onRemoved?.call(image);
                  controller.removeImage(image);
                });
              },
              icon: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: .circular(15),
                ),
                child: Icon(Icons.delete),
              ),
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
                  controller.prevSlide();
                }),
                icon: Icon(Icons.chevron_left_sharp),
              ),
              ...controller.images
                  .sublist(controller.leftIndex, controller.rightIndex + 1)
                  .map<Widget>(
                    (image) => SizedBox(
                      height: 15,
                      width: 15,
                      child: OutlinedButton(
                        onPressed: () {
                          int index = controller.images.indexOf(image);
                          if (controller.activeImage == image) {
                            return;
                          }
                          setState(() {
                            controller.activeIndex = index;
                          });
                        },

                        style: OutlinedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(0),
                          side: const BorderSide(width: 1, color: Colors.black),
                          backgroundColor: controller.activeImage == image
                              ? Colors.black
                              : Colors.white,
                        ),
                        child: SizedBox(),
                      ),
                    ),
                  ),
              IconButton(
                onPressed: () => setState(() {
                  controller.nextSlide();
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

class ImageCarouselController extends ChangeNotifier {
  final List<ImageModel> images;
  int activeIndex = 0;
  int leftIndex = 0;
  int rightIndex = 0;
  int maxBullet = 5;
  ImageCarouselController({required this.images, this.maxBullet = 3})
    : rightIndex = [maxBullet, images.length - 1].min;

  ImageModel get activeImage => images[activeIndex];

  void prevSlide() {
    if (activeIndex == 0) {
      return;
    }
    activeIndex--;
    recalculateSlideLocation();
    notifyListeners();
  }

  void nextSlide() {
    if (activeIndex == images.length - 1) {
      return;
    }
    activeIndex++;
    recalculateSlideLocation();
    notifyListeners();
  }

  void addImage(ImageModel imageModel) {
    images.add(imageModel);
    recalculateSlideLocation();
    notifyListeners();
  }

  void addImages(List<ImageModel> imageModels) {
    images.addAll(imageModels);
    recalculateSlideLocation();
    notifyListeners();
  }

  void setImages(List<ImageModel> imageModels) {
    images.clear();
    images.addAll(imageModels);
    recalculateSlideLocation();
    notifyListeners();
  }

  void clearImages() {
    images.clear();
    recalculateSlideLocation();
    notifyListeners();
  }

  void removeImage(ImageModel imageModel) {
    images.remove(imageModel);
    recalculateSlideLocation();
    notifyListeners();
  }

  void recalculateSlideLocation() {
    final imageCount = images.length;
    if (activeIndex > imageCount - 1) {
      activeIndex = [0, imageCount - 1].max;
    }
    int halfCount = (maxBullet.toDouble() / 2.0).floor();

    rightIndex = activeIndex + halfCount;
    leftIndex = activeIndex - halfCount;

    if (rightIndex > imageCount - 1) {
      rightIndex = imageCount - 1;
      leftIndex = [0, rightIndex - maxBullet + 1].max;
    } else if (leftIndex < 0) {
      leftIndex = 0;
      rightIndex = [imageCount - 1, maxBullet - 1].min;
    }
  }
}
