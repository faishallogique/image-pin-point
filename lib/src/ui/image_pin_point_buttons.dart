import 'package:flutter/material.dart';
import 'package:image_pin_point/image_pin_point.dart';
import 'package:image_pin_point/src/controller/image_pin_point_controller.dart';

/// A widget that provides UI controls for the ImagePinPoint functionality
///
/// This widget displays:
/// - A set of buttons for selecting different pin types (with different colors and labels)
/// - A clear button to remove all pins
/// - A save button to save the image with pins to the device gallery
///
/// It uses the [ImagePinPointController] mixin to access image saving functionality.
class ImagePinPointButtons extends StatelessWidget
    with ImagePinPointController {
  /// Creates an ImagePinPointButtons widget
  ///
  /// [onSelectedButtonTapped] - Callback when a pin button is selected
  /// [onClearButtonTapped] - Callback when the clear button is pressed
  /// [imageKey] - Key to the image container for saving functionality
  ImagePinPointButtons({
    super.key,
    required this.onSelectedButtonTapped,
    required this.onClearButtonTapped,
  });

  /// Callback triggered when a pin button is selected
  final ValueChanged<Pinner> onSelectedButtonTapped;

  /// Callback triggered when the clear button is pressed
  final Function() onClearButtonTapped;

  /// Predefined pin configurations with different colors and labels
  final pinnerConfigs = [
    const PinnerConfig(label: "1", color: Colors.red),
    const PinnerConfig(label: "2", color: Colors.green),
    const PinnerConfig(label: "3", color: Colors.blue),
    const PinnerConfig(label: "4", color: Colors.yellow),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Pin selection buttons displayed in a wrap layout
          Wrap(
            spacing: 10,
            children: pinnerConfigs
                .map((config) => _buildButton(
                    config.label, config.color, onSelectedButtonTapped))
                .toList(),
          ),
          const Divider(),
          // Action buttons for clearing pins and saving the image
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onClearButtonTapped,
                icon: const Icon(Icons.clear),
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  await saveImage(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds an individual pin selection button
  ///
  /// [label] - Text displayed on the button
  /// [color] - Background color of the button
  /// [onSelectedButtonTapped] - Callback when this button is pressed
  Widget _buildButton(String label, Color color,
      final Function(Pinner selectedPinner) onSelectedButtonTapped) {
    return ElevatedButton(
      onPressed: () {
        onSelectedButtonTapped.call(
            Pinner(color: color, label: label, position: const Offset(0, 0)));
      },
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

/// Configuration class for pin buttons
///
/// Defines the appearance and identity of each pin type
class PinnerConfig {
  /// Text label displayed on the pin and button
  final String label;

  /// Color of the pin and button
  final Color color;

  /// Creates a pin configuration
  const PinnerConfig({required this.label, required this.color});
}
