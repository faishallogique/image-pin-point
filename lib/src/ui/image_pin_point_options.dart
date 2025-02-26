import 'package:flutter/material.dart';

/// A widget that provides UI controls for the ImagePinPoint functionality
///
/// This widget displays a set of buttons for selecting different pin types
/// in a wrapped layout that adapts to available space.
class ImagePinPointOptions extends StatelessWidget {
  /// Creates an ImagePinPointOptions widget
  ///
  /// Parameters:
  /// - [pinOptions]: List of widgets representing different pin configurations
  ///   that will be displayed in a wrapped layout for selection
  const ImagePinPointOptions({
    super.key,
    required this.pinOptions,
  });

  /// List of widgets representing different pin configurations
  /// These will be displayed in a wrapped layout for selection
  final List<Widget> pinOptions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        alignment: WrapAlignment.center,
        children: pinOptions,
      ),
    );
  }
}
