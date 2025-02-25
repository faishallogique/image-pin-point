import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_pin_point/src/constants/constants.dart';
import 'package:image_pin_point/src/domain/pinner.dart';
import 'package:image_pin_point/src/ui/pinner_painter_widget.dart';
import 'package:image_pin_point/src/utils/common_utils.dart';

import '../controller/image_pin_point_controller.dart';

/// Style configuration for pins including radius and label text style
///
/// This class defines the visual appearance of pins placed on the image:
/// - [radius]: Controls the size of the circular pin markers (default: 10.0)
/// - [labelStyle]: Defines the text style for pin labels (default: white, size 12)
class PinStyle {
  final double radius;
  final TextStyle labelStyle;

  const PinStyle({
    this.radius = 10.0,
    this.labelStyle = const TextStyle(color: Colors.white, fontSize: 12),
  });
}

/// A widget that displays an image and allows adding pins/markers at specific points
///
/// This widget provides functionality to:
/// - Display an image from network or file source
/// - Show existing pins at specific coordinates on the image
/// - Add new pins by tapping on the image
/// - Maintain proper aspect ratio of the original image
/// - Notify parent widgets when pins are added or changed
class ImagePinPointContainer extends StatefulWidget {
  const ImagePinPointContainer({
    super.key,
    this.initialPins = const [],
    required this.imageSource,
    this.selectedPinner,
    this.pinStyle = const PinStyle(),
    required this.onPinsChanged,
  });

  /// Initial list of pins to display on the image
  /// These pins will be shown when the widget first loads
  final List<Pinner> initialPins;

  /// Source path/URL of the image to display
  /// Can be either a network URL or a local file path
  final String imageSource;

  /// Currently selected pin style and properties
  /// When set, defines the appearance of new pins added to the image
  final Pinner? selectedPinner;

  /// Style configuration for all pins
  /// Controls the visual appearance of all pins on the image
  final PinStyle pinStyle;

  /// Callback triggered when pins are added/modified
  /// Provides the updated list of all pins on the image
  final void Function(List<Pinner> pins) onPinsChanged;

  @override
  State<ImagePinPointContainer> createState() => _ImagePinPointContainerState();
}

/// The state class for ImagePinPointContainer that manages pin placement and image display
///
/// This class:
/// - Tracks the current list of pins on the image
/// - Handles image loading and dimension calculation
/// - Processes tap events to add new pins
/// - Manages the widget lifecycle and updates
class _ImagePinPointContainerState extends State<ImagePinPointContainer>
    with ImagePinPointController {
  /// List of all pins currently on the image
  /// Updated when new pins are added or when initialPins changes
  late List<Pinner> pins;

  /// Dimensions of the loaded image
  /// Used to maintain proper aspect ratio and calculate pin positions
  late double imageWidth;
  late double imageHeight;

  /// Currently selected pin for adding to image
  /// Determines the appearance of new pins when tapping the image
  Pinner? selectedPinner;

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    imageWidth = 1.0;
    imageHeight = 1.0;
    pins = widget.initialPins;
    selectedPinner = widget.selectedPinner;
    _updateImageDimensions();
  }

  @override
  void didUpdateWidget(ImagePinPointContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset pins if image source changes
    if (oldWidget.imageSource != widget.imageSource) {
      _updateImageDimensions();
      setState(() {
        pins = [];
        selectedPinner = null;
      });
    }

    // Update pins if initial pins list changes
    if (!listEquals(oldWidget.initialPins, widget.initialPins)) {
      setState(() {
        pins = widget.initialPins;
      });
    }

    // Update selected pinner if it changes
    if (oldWidget.selectedPinner != widget.selectedPinner) {
      setState(() {
        selectedPinner = widget.selectedPinner;
      });
    }
  }

  /// Loads and updates the image dimensions when image source changes
  ///
  /// This method:
  /// - Loads the image from the provided source
  /// - Extracts the original width and height
  /// - Updates the state with the new dimensions
  /// - Handles any errors that occur during loading
  void _updateImageDimensions() {
    loadImageAspectRatio(widget.imageSource, (info) {
      try {
        if (mounted) {
          setState(() {
            imageWidth = info.image.width.toDouble();
            imageHeight = info.image.height.toDouble();
          });
        }
      } catch (e) {
        log('DebugError: loading image: $e');
      }
    });
  }

  /// Adds a new pin at the tapped location
  ///
  /// This method:
  /// - Checks if a pin type is selected
  /// - Converts tap coordinates to image coordinates
  /// - Creates a new pin at the adjusted position
  /// - Updates the pins list and notifies listeners
  void _addPin(TapDownDetails details) {
    if (selectedPinner == null) return;

    onTapDown(details, Constants.imageKey, (adjustedPosition) {
      setState(() {
        pins = [
          ...pins,
          Pinner(
            position: adjustedPosition,
            color: selectedPinner!.color,
            label: selectedPinner!.label,
          )
        ];
        widget.onPinsChanged.call(pins);
      });
    }, imageWidth, imageHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        key: Constants.imageKey,
        aspectRatio: imageWidth / imageHeight,
        child: GestureDetector(
          onTapDown: _addPin,
          child: Stack(
            children: [
              _buildImage(),
              PinnerPainterWidget(pins: pins, pinStyle: widget.pinStyle),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the image widget based on source type (network or file)
  ///
  /// This method:
  /// - Determines if the image source is a network URL or local file
  /// - Creates the appropriate image widget with error handling
  /// - Applies consistent fit and error display across source types
  /// - Catches and logs any exceptions during image creation
  Widget _buildImage() {
    try {
      return CommonUtils.isImageFromNetwork(widget.imageSource)
          ? CachedNetworkImage(
              imageUrl: widget.imageSource,
              fit: BoxFit.contain,
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error)),
            )
          : Image.file(
              File(widget.imageSource),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.error)),
            );
    } catch (e) {
      log('DebugError: building image: $e');
      return const Center(child: Icon(Icons.error));
    }
  }
}
