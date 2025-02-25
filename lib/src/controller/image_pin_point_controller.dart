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

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:image_pin_point/src/constants/constants.dart';
import 'package:image_pin_point/src/utils/common_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

/// A mixin class that provides methods for image manipulation and pin point functionality
///
/// This mixin can be used by any widget that needs to handle image operations such as:
/// - Loading images and determining their dimensions
/// - Converting tap coordinates to image coordinates
/// - Capturing and saving images with pins to the device gallery
/// - Handling image orientation issues that may occur on different devices
mixin class ImagePinPointController {
  /// Loads an image and calculates its aspect ratio
  ///
  /// [imageSource] can be either a network URL or a local file path
  /// [callBack] is called with the loaded image information
  ///
  /// This method creates an appropriate image provider based on the source type,
  /// then resolves the image and provides dimension information through the callback.
  Future<void> loadImageAspectRatio(
      String imageSource, Function(ImageInfo) callBack) async {
    final image = Image(
      image: imageSource.startsWith('http') || imageSource.startsWith('https')
          ? CachedNetworkImageProvider(imageSource)
          : FileImage(File(imageSource)),
    );

    final ImageStream stream = image.image.resolve(const ImageConfiguration());

    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        callBack.call(info);
      }),
    );
  }

  /// Processes tap events and converts tap coordinates to image coordinates
  ///
  /// Takes into account:
  /// - Container size and position
  /// - Image size and aspect ratio
  /// - Bounds checking to ensure tap is within image
  ///
  /// [details] contains the tap information including global position
  /// [imageKey] is the key to the widget containing the image
  /// [callBack] is called with the adjusted position if the tap is valid
  /// [imageWidth] and [imageHeight] are the dimensions of the original image
  void onTapDown(
    TapDownDetails details,
    GlobalKey<State<StatefulWidget>> imageKey,
    Function(Offset) callBack,
    double imageWidth,
    double imageHeight,
  ) {
    // Convert global tap position to local position within the image container
    RenderBox box = imageKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(details.globalPosition);

    // Get the size of the container and calculate the actual image size within it
    Size containerSize = box.size;
    Size imageSize =
        CommonUtils.getImageSize(imageWidth, imageHeight, containerSize);

    // Convert the tap position to coordinates relative to the original image dimensions
    Offset adjustedPosition = Offset(
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

  /// Saves the current image state including pins to the device gallery
  ///
  /// Process:
  /// 1. Captures the current widget state as an image
  /// 2. Checks if the image needs to be flipped (some devices flip images during capture)
  /// 3. Saves the processed image to the gallery
  /// 4. Shows a success/error message
  ///
  /// [imageKey] is the key to the widget containing the image to be saved
  /// [context] is the build context, used for showing feedback to the user
  Future<void> saveImage(BuildContext context) async {
    try {
      // Capture the current state of the widget as an image
      final boundary = Constants.imageKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.5);

      // Convert the captured image to bytes
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List? imageBytes = byteData?.buffer.asUint8List();

      if (imageBytes == null) {
        log('DebugError: Failed to capture image');
        return;
      }

      // Create a temporary file to check if the image is flipped
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_image.png';
      final tempFile = File(filePath);
      await tempFile.writeAsBytes(imageBytes);

      // Check if the image is flipped (happens on some devices)
      final isFlipped = await _isImageFlipped(
        tempFile,
        imageBytes,
      );

      log('DebugInfo: isFlipped: $isFlipped');

      // Correct the orientation if needed
      if (isFlipped) {
        imageBytes = await _flipImageVertically(imageBytes);
      }

      // Save the image to the gallery with a unique filename
      String fileName = '${DateTime.now().microsecondsSinceEpoch}.png';
      final res = await SaverGallery.saveImage(imageBytes!,
          fileName: fileName, skipIfExists: false);

      // Clean up the temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      log('DebugSuccess: Image saved successfully: $res');

      // Show feedback to the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.isSuccess ? 'Success save' : '${res.errorMessage}',
            ),
          ),
        );
      }
    } catch (e) {
      log('DebugError: error save: $e');
    }
  }

  /// Flips an image vertically using Flutter's Canvas API
  ///
  /// Used to correct image orientation issues on some devices
  /// Returns the flipped image as a Uint8List or null if the operation fails
  ///
  /// [imageBytes] is the original image data to be flipped
  ///
  /// The method works by:
  /// 1. Decoding the original image
  /// 2. Creating a new canvas and applying transformations to flip the image
  /// 3. Converting the result back to bytes
  Future<Uint8List?> _flipImageVertically(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      for (int i = 0; i < 2; i++) {
        // Move to bottom and flip vertically
        canvas.translate(0, image.height.toDouble());
        canvas.scale(1, -1);
        canvas.drawImage(image, Offset.zero, Paint());
      }

      final picture = recorder.endRecording();
      final flippedImage = await picture.toImage(image.width, image.height);

      final byteData = await flippedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Dispose resources
      image.dispose();
      flippedImage.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      log('DebugError: flipping image: $e');
      return null;
    }
  }

  /// Checks if an image is vertically flipped by comparing pixels
  ///
  /// Compares the top row of the original image with the bottom row of the saved image
  /// Returns true if the image appears to be flipped vertically
  ///
  /// [savedImageFile] is the file containing the potentially flipped image
  /// [originalImageBytes] is the original image data before saving
  ///
  /// The method works by:
  /// 1. Decoding both the original and saved images
  /// 2. Comparing pixels from the top row of the original with the bottom row of the saved image
  /// 3. If they match, the image is likely flipped
  Future<bool> _isImageFlipped(
    File savedImageFile,
    Uint8List originalImageBytes,
  ) async {
    try {
      // Decode original image
      img.Image? originalImage = img.decodeImage(originalImageBytes);
      if (originalImage == null) return false;

      // Decode saved image
      Uint8List savedImageBytes = await savedImageFile.readAsBytes();
      img.Image? savedImage = img.decodeImage(savedImageBytes);
      if (savedImage == null) return false;

      // Ensure both images are the same size
      if (originalImage.width != savedImage.width ||
          originalImage.height != savedImage.height) {
        return false;
      }

      int width = originalImage.width;
      int height = originalImage.height;

      // Compare pixels from the first and last row
      for (int x = 0; x < width; x++) {
        final originalTopPixel = originalImage.getPixel(x, 0);
        final savedBottomPixel = savedImage.getPixel(x, height - 1);

        if (originalTopPixel != savedBottomPixel) {
          return false; // If pixels don't match, it's not flipped
        }
      }

      return true; // The image is flipped if the top row matches the bottom row
    } catch (e) {
      log("DebugError: checking flipped image: $e");
      return false;
    }
  }
}
