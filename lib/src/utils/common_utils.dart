import 'dart:ui';

/// A utility class providing common helper methods for image handling
class CommonUtils {
  /// Checks if the provided image source is a network URL
  ///
  /// Returns true if the [imageSource] starts with 'http' or 'https',
  /// indicating it's a network image URL rather than a local file path
  static bool isImageFromNetwork(String imageSource) {
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
  static Size getImageSize(
      double imageWidth, double imageHeight, Size containerSize) {
    double imageAspectRatio = imageWidth / imageHeight;
    double containerAspectRatio = containerSize.width / containerSize.height;

    if (containerAspectRatio > imageAspectRatio) {
      // Container is wider than image - fit to height
      double displayedHeight = containerSize.height;
      double displayedWidth = displayedHeight * imageAspectRatio;
      return Size(displayedWidth, displayedHeight);
    } else {
      // Container is taller than image - fit to width
      double displayedWidth = containerSize.width;
      double displayedHeight = displayedWidth / imageAspectRatio;
      return Size(displayedWidth, displayedHeight);
    }
  }
}
