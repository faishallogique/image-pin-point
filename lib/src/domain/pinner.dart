import 'package:flutter/material.dart';

/// A customizable pin that can contain any widget as its visual representation
///
/// This class allows for flexible pin designs by:
/// - Storing the exact position where the pin should be placed
/// - Containing any Flutter widget to be rendered at that position
/// - Supporting the pin positioning system used in ImagePinPointContainer
class Pinner {
  /// The position of the pin on the image (in image coordinates)
  final Offset position;

  /// The widget to be displayed at the pin position
  final Widget widget;

  /// Creates a new custom pin with the specified position and widget
  const Pinner({
    required this.position,
    required this.widget,
  });
}
