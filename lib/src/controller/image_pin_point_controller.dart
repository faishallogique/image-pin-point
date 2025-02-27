/// A controller mixin that provides functionality for handling image operations in the ImagePinPoint widget
///
/// This controller handles:
/// - Loading and calculating image aspect ratios
/// - Processing tap events and converting tap coordinates
/// - Saving images with pins to the device gallery
/// - Handling image orientation and flipping issues
///
/// Usage:
/// ```dart
/// class MyWidget extends StatefulWidget with ImagePinPointController {
///   // Your widget implementation
/// }
/// ```
library;

import 'package:flutter/material.dart';
import 'package:image_pin_point/src/utils/image_utils.dart';

/// A mixin class that provides methods for image manipulation and pin point functionality
///
/// This mixin can be used by any widget that needs to handle image operations such as:
/// - Loading images and determining their dimensions
/// - Converting tap coordinates to image coordinates
/// - Capturing and saving images with pins to the device gallery
/// - Handling image orientation issues that may occur on different devices
mixin class ImagePinPointController {
  /// Processes tap events and converts tap coordinates to image coordinates
  ///
  /// This method handles the complex task of translating screen tap positions to
  /// coordinates relative to the original image, accounting for scaling and positioning.
  ///
  /// Parameters:
  /// - [details]: Contains the tap information including global position
  /// - [imageKey]: Key to the widget containing the image
  /// - [callBack]: Called with the adjusted position if the tap is valid
  /// - [imageWidth]: Original width of the image
  /// - [imageHeight]: Original height of the image
  ///
  /// The method performs several important steps:
  /// 1. Converts global tap position to local position within the image container
  /// 2. Calculates the actual image size within the container (accounting for aspect ratio)
  /// 3. Maps the tap coordinates to the original image dimensions
  /// 4. Validates that the tap is within the image bounds
  /// 5. Calls the callback with the properly adjusted position
  void onTapDown(
    TapDownDetails details,
    GlobalKey<State<StatefulWidget>> imageKey,
    Function(Offset) callBack,
    double imageWidth,
    double imageHeight,
  ) {
    // Convert global tap position to local position within the image container
    final RenderBox box =
        imageKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    // Get the size of the container and calculate the actual image size within it
    final Size containerSize = box.size;
    final Size imageSize =
        ImageUtils.calculateDisplaySize(imageWidth, imageHeight, containerSize);

    // Convert the tap position to coordinates relative to the original image dimensions
    final Offset adjustedPosition = Offset(
      (localPosition.dx / containerSize.width) * imageSize.width,
      (localPosition.dy / containerSize.height) * imageSize.height,
    );

    // Ensure the tap is within the image bounds
    if (adjustedPosition.dx < 0 ||
        adjustedPosition.dx > imageWidth ||
        adjustedPosition.dy < 0 ||
        adjustedPosition.dy > imageHeight) {
      return;
    }

    // Call the callback with the adjusted position
    callBack.call(adjustedPosition);
  }
}
