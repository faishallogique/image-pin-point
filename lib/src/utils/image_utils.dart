import 'dart:ui';

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
}
