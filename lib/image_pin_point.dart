library image_pin_point;

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:image_pin_point/src/constants/log_messages.dart';
import 'package:image_pin_point/src/domain/operation_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

export 'src/controller/image_pin_point_controller.dart';
export 'src/domain/pinner.dart';
export 'src/ui/image_pin_point_container.dart';
export 'src/ui/image_pin_point_options.dart';

/// A utility class that provides functionality for capturing, processing, and saving images with pins
///
/// This class contains static methods for:
/// - Capturing the current state of an ImagePinPoint widget
/// - Handling image orientation issues
/// - Saving images to the device gallery
class ImagePinPoint {
  /// Saves the current image state including pins to the device gallery
  ///
  /// This method captures the current visual state of the widget (including all pins),
  /// processes the image to correct any orientation issues, and saves it to the device gallery.
  ///
  /// Parameters:
  /// - [imagePinPointKey]: The GlobalKey of the widget to capture
  /// - [skipSaveToGallery]: If true, the image will only be saved to a temporary file
  ///
  /// Returns:
  /// - A [OperationResult] object containing success/failure information and file path
  ///
  /// The method follows these steps:
  /// 1. Captures the current widget state as an image using RepaintBoundary
  /// 2. Converts the captured image to bytes
  /// 3. Creates a temporary file to check if the image needs orientation correction
  /// 4. Applies vertical flipping if needed (some devices flip images during capture)
  /// 5. Saves the processed image to the gallery with a unique timestamp-based filename
  /// 6. Cleans up temporary files and returns success/error feedback to the user
  ///
  /// Error handling is implemented throughout the process with appropriate logging.
  static Future<OperationResult> saveImage(GlobalKey imagePinPointKey,
      {bool skipSaveToGallery = true}) async {
    try {
      // Capture the current state of the widget as an image
      final RenderRepaintBoundary boundary = imagePinPointKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);

      // Convert the captured image to bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List? imageBytes = byteData?.buffer.asUint8List();

      if (imageBytes == null) {
        log(LogMessages.errorCapturingImage);
        return OperationResult(
            isSuccess: false, message: 'Failed to capture image');
      }

      // Create a temporary file to check if the image is flipped
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/temp_${DateTime.now().microsecondsSinceEpoch}.png';
      final File tempFileToCheckOrientation = File(filePath);
      await tempFileToCheckOrientation.writeAsBytes(imageBytes);

      // Check if the image is flipped (happens on some devices)
      final bool isFlipped = await _isImageFlipped(
        tempFileToCheckOrientation,
        imageBytes,
      );

      log('${LogMessages.infoImageFlipState}: $isFlipped');

      // Correct the orientation if needed
      if (isFlipped) {
        imageBytes = await _flipImageVertically(imageBytes);
      }

      // Clean up the temporary file
      if (await tempFileToCheckOrientation.exists()) {
        await tempFileToCheckOrientation.delete();
      }

      // Create a local copy of the saved image with the same filename
      // This allows us to return the file path in the OperationResult
      // while still saving the image to the gallery
      final String fileName = '${DateTime.now().microsecondsSinceEpoch}.png';
      final String finalFilePath = '${tempDir.path}/$fileName';
      final File finalFile = File(finalFilePath)..createSync(recursive: true);
      await finalFile.writeAsBytes(imageBytes!);

      if (!skipSaveToGallery) {
        await SaverGallery.saveImage(
          imageBytes,
          fileName: fileName,
          skipIfExists: false,
        );
      }

      return OperationResult(
          isSuccess: true,
          filePath: finalFile.path,
          message: 'Image saved successfully');
    } catch (e) {
      log('${LogMessages.errorSavingImage}: $e');

      return OperationResult(isSuccess: false, message: 'Failed to save image');
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
  static Future<Uint8List?> _flipImageVertically(Uint8List imageBytes) async {
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
      log('${LogMessages.errorFlippingImage}: $e');
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
  static Future<bool> _isImageFlipped(
    File tempSavedImageFile,
    Uint8List originalImageBytes,
  ) async {
    try {
      // Decode original image
      final img.Image? originalImage = img.decodeImage(originalImageBytes);
      if (originalImage == null) return false;

      // Decode saved image
      final Uint8List savedImageBytes = await tempSavedImageFile.readAsBytes();
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
      log('${LogMessages.errorCheckingFlippedImage}: $e');
      return false;
    }
  }
}
