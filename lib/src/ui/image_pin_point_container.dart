import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_pin_point/src/constants/constants.dart';
import 'package:image_pin_point/src/domain/pinner.dart';
import 'package:image_pin_point/src/utils/common_utils.dart';

import '../controller/image_pin_point_controller.dart';

/// A widget that displays an image and allows adding pins/markers at specific points
///
/// This widget provides functionality to:
/// - Display an image from network or file source
/// - Show existing pins at specific coordinates on the image
/// - Add new pins by tapping on the image after selecting a pin config
/// - Maintain proper aspect ratio of the original image
/// - Notify parent widgets when pins are added or changed
class ImagePinPointContainer extends StatefulWidget {
  /// Creates an image container that supports pin placement
  ///
  /// Parameters:
  /// - [imageSource]: Path or URL to the image (required)
  /// - [initialPins]: List of pins to display initially
  /// - [selectedPinner]: Currently selected pin type for adding new pins
  /// - [onPinsChanged]: Callback when pins are added or modified
  const ImagePinPointContainer({
    super.key,
    this.initialPins = const [],
    required this.imageSource,
    this.selectedPinner,
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

  /// Width of the loaded image in pixels
  late double imageWidth;

  /// Height of the loaded image in pixels
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
            widget: selectedPinner!.widget,
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
        aspectRatio: imageWidth / imageHeight,
        child: RepaintBoundary(
          key: Constants.imageKey,
          child: GestureDetector(
            onTapDown: _addPin,
            child: Stack(
              children: [
                _buildImage(),
                if (pins.isNotEmpty)
                  ...pins.map((pinWidget) {
                    return Positioned(
                      left: pinWidget.position.dx,
                      top: pinWidget.position.dy,
                      child: CenteredPinWidget(
                        child: Material(
                          color: Colors.transparent,
                          child: pinWidget.widget,
                        ),
                      ),
                    );
                  }),
              ],
            ),
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

/// A widget that centers its child at the origin point
///
/// This widget ensures that pins are properly centered at their exact coordinates
/// by measuring the child widget's size and applying an appropriate offset.
class CenteredPinWidget extends StatefulWidget {
  /// The widget to be centered (typically a pin marker)
  final Widget child;

  /// Creates a widget that centers its child at the origin point
  const CenteredPinWidget({
    super.key,
    required this.child,
  });

  @override
  State<CenteredPinWidget> createState() => _CenteredPinWidgetState();
}

/// State for the CenteredPinWidget that handles measurement and positioning
class _CenteredPinWidgetState extends State<CenteredPinWidget> {
  /// Key used to access the child widget for measurement
  final GlobalKey _childKey = GlobalKey();

  /// Size of the child widget after measurement
  Size _childSize = Size.zero;

  /// Whether the child has been measured yet
  bool _isMeasured = false;

  @override
  void initState() {
    super.initState();
    // Schedule a post-frame callback to measure the child
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChild());
  }

  /// Measures the size of the child widget
  ///
  /// This method:
  /// - Accesses the render object of the child widget
  /// - Extracts its dimensions
  /// - Updates the state with the measured size
  void _measureChild() {
    final RenderBox? renderBox =
        _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      setState(() {
        _childSize = renderBox.size;
        _isMeasured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMeasured) {
      // First build: measure the child using offscreen rendering
      return Offstage(
        offstage: true, // Hide during measurement without using Opacity
        child: Container(
          key: _childKey,
          child: widget.child,
        ),
      );
    } else {
      // Subsequent builds: apply the offset
      return Transform.translate(
        offset: Offset(-_childSize.width / 2, -_childSize.height / 2),
        child: widget.child,
      );
    }
  }
}
