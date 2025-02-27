/// Constants used for logging and debugging throughout the application
///
/// This class provides standardized error and info message prefixes
/// to maintain consistency in log outputs across the application.
class LogMessages {
  /// Error prefix for image building failures
  static const String errorBuildingImage = 'Error: building image: ';

  /// Error prefix for image capture failures
  static const String errorCapturingImage = 'Error: capturing image: ';

  /// Error prefix for image flipping failures
  static const String errorFlippingImage = 'Error: flipping image: ';

  /// Error prefix for image saving failures
  static const String errorSavingImage = 'Error: saving image: ';

  /// Info prefix for image flip state logging
  static const String infoImageFlipState = 'Info: image flip state: ';

  /// Error prefix for checking image flip state failures
  static const String errorCheckingFlippedImage =
      'Error: checking flipped image: ';

  /// Error prefix for loading image dimensions failures
  static const String errorLoadingImageDimensions =
      'Error: loading image dimensions: ';

  /// Error prefix for adding pin failures
  static const String errorAddingPin = 'Error: adding pin: ';
}
