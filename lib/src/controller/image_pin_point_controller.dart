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
  /// This method creates an appropriate image provider based on the source type,
  /// then resolves the image and provides dimension information through the callback.
  ///
  /// Parameters:
  /// - [imageSource]: Can be either a network URL or a local file path
  /// - [callBack]: Called with the loaded image information once available
  ///
  /// The callback provides access to the image dimensions needed for proper scaling
  /// and positioning of pins on the image.
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
        CommonUtils.getImageSize(imageWidth, imageHeight, containerSize);

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

  /// Saves the current image state including pins to the device gallery
  ///
  /// This method captures the current visual state of the widget (including all pins),
  /// processes the image to correct any orientation issues, and saves it to the device gallery.
  ///
  /// Parameters:
  /// - [context]: The build context, used for showing feedback to the user
  ///
  /// The method follows these steps:
  /// 1. Captures the current widget state as an image using RepaintBoundary
  /// 2. Converts the captured image to bytes
  /// 3. Creates a temporary file to check if the image needs orientation correction
  /// 4. Applies vertical flipping if needed (some devices flip images during capture)
  /// 5. Saves the processed image to the gallery with a unique timestamp-based filename
  /// 6. Cleans up temporary files and shows success/error feedback to the user
  ///
  /// Error handling is implemented throughout the process with appropriate logging.
  Future<void> saveImage(BuildContext context) async {
    try {
      // Capture the current state of the widget as an image
      final RenderRepaintBoundary boundary = Constants.imageKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);

      // Convert the captured image to bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List? imageBytes = byteData?.buffer.asUint8List();

      if (imageBytes == null) {
        log('DebugError: Failed to capture image');
        return;
      }

      // Create a temporary file to check if the image is flipped
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/temp_image.png';
      final File tempFile = File(filePath);
      await tempFile.writeAsBytes(imageBytes);

      // Check if the image is flipped (happens on some devices)
      final bool isFlipped = await _isImageFlipped(
        tempFile,
        imageBytes,
      );

      log('DebugInfo: isFlipped: $isFlipped');

      // Correct the orientation if needed
      if (isFlipped) {
        imageBytes = await _flipImageVertically(imageBytes);
      }

      // Save the image to the gallery with a unique filename
      final String fileName = '${DateTime.now().microsecondsSinceEpoch}.png';
      final result = await SaverGallery.saveImage(
        imageBytes!,
        fileName: fileName,
        skipIfExists: false,
      );

      // Clean up the temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      log('DebugSuccess: Image saved successfully: $result');

      // Show feedback to the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isSuccess
                  ? 'Image saved successfully'
                  : '${result.errorMessage}',
            ),
          ),
        );
      }
    } catch (e) {
      log('DebugError: error saving image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image'),
          ),
        );
      }
    }
  }

  /// Flips an image vertically using Flutter's Canvas API
  ///
  /// This method corrects image orientation issues that can occur on some devices
  /// during the capture process. It creates a new image with the correct orientation.
  ///
  /// Parameters:
  /// - [imageBytes]: The original image data to be flipped
  ///
  /// Returns:
  /// - A Uint8List containing the flipped image data, or null if the operation fails
  ///
  /// The method works by:
  /// 1. Decoding the original image
  /// 2. Creating a new canvas and applying transformations to flip the image vertically
  /// 3. Converting the result back to bytes
  /// 4. Properly disposing of resources to prevent memory leaks
  Future<Uint8List?> _flipImageVertically(Uint8List imageBytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Apply transformations to flip the image vertically
      canvas.translate(0, image.height.toDouble());
      canvas.scale(1, -1);
      canvas.drawImage(image, Offset.zero, Paint());

      final ui.Picture picture = recorder.endRecording();
      final ui.Image flippedImage =
          await picture.toImage(image.width, image.height);

      final ByteData? byteData = await flippedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Dispose resources to prevent memory leaks
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
  /// This method determines if an image needs orientation correction by comparing
  /// the top row of the original image with the bottom row of the saved image.
  ///
  /// Parameters:
  /// - [savedImageFile]: The file containing the potentially flipped image
  /// - [originalImageBytes]: The original image data before saving
  ///
  /// Returns:
  /// - true if the image appears to be flipped vertically, false otherwise
  ///
  /// The detection works by:
  /// 1. Decoding both the original and saved images
  /// 2. Comparing pixels from the top row of the original with the bottom row of the saved image
  /// 3. If a significant number of pixels match, the image is likely flipped
  ///
  /// This is necessary because some devices or rendering processes may flip images
  /// during the capture and save process.
  Future<bool> _isImageFlipped(
    File savedImageFile,
    Uint8List originalImageBytes,
  ) async {
    try {
      // Decode original image
      final img.Image? originalImage = img.decodeImage(originalImageBytes);
      if (originalImage == null) return false;

      // Decode saved image
      final Uint8List savedImageBytes = await savedImageFile.readAsBytes();
      final img.Image? savedImage = img.decodeImage(savedImageBytes);
      if (savedImage == null) return false;

      // Ensure both images are the same size
      if (originalImage.width != savedImage.width ||
          originalImage.height != savedImage.height) {
        return false;
      }

      final int width = originalImage.width;
      final int height = originalImage.height;

      // Compare pixels from the first and last row
      // We use a sample of pixels across the width to determine if flipped
      int matchCount = 0;
      final int sampleSize = width;

      for (int x = 0; x < width; x += width ~/ sampleSize) {
        final originalTopPixel = originalImage.getPixel(x, 0);
        final savedBottomPixel = savedImage.getPixel(x, height - 1);

        if (originalTopPixel == savedBottomPixel) {
          matchCount++;
        }
      }

      // If more than 75% of sampled pixels match, consider it flipped
      return matchCount > (sampleSize * 0.75);
    } catch (e) {
      log("DebugError: checking flipped image: $e");
      return false;
    }
  }
}
