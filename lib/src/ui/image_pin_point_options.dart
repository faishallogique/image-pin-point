import 'package:flutter/material.dart';

/// A widget that displays a collection of pin style options for the ImagePinPoint system.
///
/// This widget provides a horizontal wrap layout for pin style buttons and controls:
/// - Displays pin style options (such as different colors or shapes)
/// - Supports utility buttons (clear, save, etc.)
/// - Automatically wraps to new lines when space is limited
/// - Centers all options for better visual presentation
class ImagePinPointOptions extends StatelessWidget {
  /// The list of widgets representing different pin styles and their actions.
  ///
  /// These are typically buttons that you design which, when pressed, will:
  /// - Select a pin style to be added to the image by setting the [selectedPinStyle]
  /// - Perform actions such as resetting pins by clearing the [pinsOnTheImage]
  /// - Save the image by calling the [ImagePinPoint.saveImage] method
  const ImagePinPointOptions({
    super.key,
    required this.pinStyleOptions,
  });

  final List<Widget> pinStyleOptions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        alignment: WrapAlignment.center,
        children: pinStyleOptions,
      ),
    );
  }
}
