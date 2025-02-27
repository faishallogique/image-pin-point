import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A utility class providing common helper methods for image handling
class ImageUtils {
  /// Determines if the provided image source is from a network URL
  ///
  /// Returns true if the [imageSource] starts with 'http' or 'https',
  /// indicating it's a network image URL rather than a local file path
  static bool isNetworkImage(String imageSource) {
    return imageSource.startsWith('http') || imageSource.startsWith('https');
  }

  /// Calculates the displayed size of an image while maintaining aspect ratio
  ///
  /// Given the original [imageWidth] and [imageHeight] along with the [containerSize],
  /// this method calculates the appropriate display dimensions that will:
  /// 1. Fit within the container bounds
  /// 2. Maintain the original aspect ratio
  /// 3. Fill the container as much as possible without distortion
  ///
  /// Returns a [Size] object containing the calculated display width and height
  static Size calculateDisplaySize(
      double imageWidth, double imageHeight, Size containerSize) {
    final double imageAspectRatio = imageWidth / imageHeight;
    final double containerAspectRatio =
        containerSize.width / containerSize.height;

    if (containerAspectRatio > imageAspectRatio) {
      // Container is wider than image - fit to height
      final double displayedHeight = containerSize.height;
      final double displayedWidth = displayedHeight * imageAspectRatio;
      return Size(displayedWidth, displayedHeight);
    } else {
      // Container is taller than image - fit to width
      final double displayedWidth = containerSize.width;
      final double displayedHeight = displayedWidth / imageAspectRatio;
      return Size(displayedWidth, displayedHeight);
    }
  }

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
  static Future<ImageInfo> loadImageAspectRatio(String imageSource) async {
    // Create the appropriate image provider based on source type
    final ImageProvider imageProvider = isNetworkImage(imageSource)
        ? CachedNetworkImageProvider(imageSource)
        : FileImage(File(imageSource)) as ImageProvider;

    // Create a completer to handle the async result
    final Completer<ImageInfo> completer = Completer<ImageInfo>();

    // Get the image stream directly from the provider
    final ImageStream stream =
        imageProvider.resolve(const ImageConfiguration());

    // Create the listener
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!completer.isCompleted) {
          completer.complete(info);
          stream.removeListener(listener);
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
          stream.removeListener(listener);
        }
      },
    );

    // Add the listener to the stream
    stream.addListener(listener);

    // Add a timeout to prevent hanging indefinitely
    Future<void>.delayed(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Image loading timed out after 30 seconds'),
        );
        stream.removeListener(listener);
      }
    });

    return completer.future;
  }
}
