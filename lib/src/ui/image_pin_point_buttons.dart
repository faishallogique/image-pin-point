import 'package:flutter/material.dart';
import 'package:image_pin_point/image_pin_point.dart';
import 'package:image_pin_point/src/controller/image_pin_point_controller.dart';

/// A widget that provides UI controls for the ImagePinPoint functionality
///
/// This widget displays:
/// - A set of buttons for selecting different pin types
/// - A clear button to remove all pins
/// - A save button to save the image with pins to the device gallery
///
/// It uses the [ImagePinPointController] mixin to access image saving functionality.
class ImagePinPointButtons extends StatelessWidget
    with ImagePinPointController {
  /// Creates an ImagePinPointButtons widget
  ///
  /// Parameters:
  /// - [onSelectedButtonTapped]: Callback when a pin button is selected
  /// - [onClearButtonTapped]: Callback when the clear button is pressed
  /// - [pinnerConfigs]: List of widgets representing different pin configurations
  ImagePinPointButtons({
    super.key,
    required this.onSelectedButtonTapped,
    required this.onClearButtonTapped,
    required this.pinnerConfigs,
  });

  /// Callback triggered when a pin button is selected
  final ValueChanged<Pinner> onSelectedButtonTapped;

  /// Callback triggered when the clear button is pressed
  final VoidCallback onClearButtonTapped;

  /// List of widgets representing different pin configurations
  /// These will be displayed in the button row for selection
  final List<Widget> pinnerConfigs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Pin selection buttons displayed in a wrap layout
          Wrap(
            spacing: 10,
            children: pinnerConfigs,
          ),
          const Divider(),
          // Action buttons for clearing pins and saving the image
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onClearButtonTapped,
                icon: const Icon(Icons.clear),
                tooltip: 'Clear all pins',
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  await saveImage(context);
                },
                tooltip: 'Save image with pins',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
