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
  /// - Select a pin style to be added to the image by setting a selected pin style
  /// - Perform actions such as clearing pins from the image
  /// - Trigger other custom actions related to image annotation
  const ImagePinPointOptions({
    super.key,
    required this.pinStyleOptions,
  });

  final List<Widget> pinStyleOptions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: pinStyleOptions,
    );
  }
}
