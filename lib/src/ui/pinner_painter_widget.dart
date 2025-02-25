import 'package:flutter/material.dart';
import 'package:image_pin_point/image_pin_point.dart';

/// A widget that paints pins (markers) on a canvas with customizable styles
///
/// This widget uses [CustomPaint] to draw pins and their labels at specified positions.
/// Each pin consists of a colored circle and a centered text label.
class PinnerPainterWidget extends StatelessWidget {
  /// List of pins to be drawn on the canvas
  final List<Pinner> pins;

  /// Style configuration for the pins including radius and label text style
  final PinStyle pinStyle;

  const PinnerPainterWidget({
    super.key,
    required this.pins,
    required this.pinStyle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PinnerPainter(
        pins,
        style: pinStyle,
      ),
      size: Size.infinite,
    );
  }
}

/// Custom painter that handles the actual drawing of pins on the canvas
class _PinnerPainter extends CustomPainter {
  /// List of pins to be painted
  final List<Pinner> pinners;

  /// Style configuration for the pins
  final PinStyle style;

  _PinnerPainter(this.pinners, {required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    // Configure paint object for filling the pin circles
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw each pin and its label
    for (var pinner in pinners) {
      // Set the pin color and draw the circle
      paint.color = pinner.color;
      canvas.drawCircle(pinner.position, style.radius, paint);

      // Create and configure text painter for the label
      final textPainter = TextPainter(
        text: TextSpan(
          text: pinner.label,
          style: style.labelStyle,
        ),
        textDirection: TextDirection.ltr,
      );

      // Layout and position the text in the center of the pin
      textPainter.layout();
      final textOffset = Offset(
        pinner.position.dx - textPainter.width / 2,
        pinner.position.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
