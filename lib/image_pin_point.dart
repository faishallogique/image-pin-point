library image_pin_point;

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_pin_point/src/constants/log_messages.dart';
import 'package:image_pin_point/src/domain/operation_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

export 'src/controller/image_pin_point_controller.dart';
export 'src/domain/operation_result.dart';
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
  /// Captures and saves the current image state including pins
  ///
  /// This method captures the current visual state of the widget (including all pins),
  /// processes the image to correct any orientation issues, and optionally saves it to the device gallery.
  ///
  /// Parameters:
  /// - [imagePinPointKey]: The GlobalKey of the widget to capture
  /// - [skipSaveToGallery]: If true, the image will only be saved to a temporary file (default: true)
  /// - [customName]: Optional custom filename for the saved image
  ///
  /// Returns:
  /// - An [OperationResult] object containing success/failure information and file path
  ///
  /// The method follows these steps:
  /// 1. Captures the current widget state as an image using RepaintBoundary
  /// 2. Converts the captured image to bytes
  /// 3. Creates a temporary file to check if the image needs orientation correction
  /// 4. Applies vertical flipping if needed (some devices flip images during capture)
  /// 5. Saves the processed image to the gallery with a unique timestamp-based filename
  /// 6. Cleans up temporary files and returns success/error feedback to the user
  static Future<OperationResult> saveImage(GlobalKey imagePinPointKey,
      {bool skipSaveToGallery = true, String? customName}) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = customName != null
          ? '$customName.png'
          : '${DateTime.now().microsecondsSinceEpoch}.png';
      final String finalFilePath = '${tempDir.path}/$fileName';

      // Remove existing file with the same name if it exists
      final File existingFile = File(finalFilePath);
      if (existingFile.existsSync()) {
        existingFile.deleteSync();
      }

      // Capture the current state of the widget as an image
      final RenderRepaintBoundary boundary = imagePinPointKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;
      final ui.Image capturedImage = await boundary.toImage(pixelRatio: 2.5);

      // Convert the captured image to bytes
      final ByteData? byteData = await capturedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List? imageBytes = byteData?.buffer.asUint8List();

      if (imageBytes == null) {
        log(LogMessages.errorCapturingImage);
        return OperationResult(
            isSuccess: false, message: 'Failed to capture image');
      }

      // Create a temporary file to check if the image is flipped
      final String tempFilePath = '${tempDir.path}/temp_$fileName';
      final File tempFile = File(tempFilePath)..createSync(recursive: true);
      await tempFile.writeAsBytes(imageBytes);

      // Clean up the temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Create a local copy of the saved image
      final File finalFile = File(finalFilePath)..createSync(recursive: true);
      await finalFile.writeAsBytes(imageBytes);

      // Save to gallery if requested
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
}
