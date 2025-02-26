import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_pin_point/image_pin_point.dart';
import 'package:image_pin_point/src/constants/log_messages.dart';
import 'package:image_pin_point/src/utils/image_utils.dart';

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
  /// - [onPinsUpdated]: Callback when pins are added or modified
  /// - [imagePinPointKey]: Key used for capturing the widget state as an image
  const ImagePinPointContainer({
    super.key,
    this.initialPins = const [],
    required this.imageSource,
    this.selectedPinner,
    required this.onPinsUpdated,
    required this.imagePinPointKey,
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
  final void Function(List<Pinner> pins) onPinsUpdated;

  /// Key used for capturing the widget state as an image
  /// This is required for the image saving functionality
  final GlobalKey imagePinPointKey;

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
class _ImagePinPointContainerState extends State<ImagePinPointContainer> {
  /// List of all pins currently on the image
  /// Updated when new pins are added or when initialPins changes
  late List<Pinner> _pins;

  /// Width of the loaded image in pixels
  late double _imageWidth;

  /// Height of the loaded image in pixels
  late double _imageHeight;

  /// Currently selected pin for adding to image
  /// Determines the appearance of new pins when tapping the image
  Pinner? _selectedPinner;

  /// Controller for handling image loading and pin placement
  final _imagePinPointController = ImagePinPointController();

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    _imageWidth = 1.0;
    _imageHeight = 1.0;
    _pins = widget.initialPins;
    _selectedPinner = widget.selectedPinner;

    _updateImageDimensions();
  }

  @override
  void didUpdateWidget(ImagePinPointContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset pins if image source changes
    if (oldWidget.imageSource != widget.imageSource) {
      _updateImageDimensions();
      setState(() {
        _pins = [];
        _selectedPinner = null;
      });
    }

    // Update pins if initial pins list changes
    if (!listEquals(oldWidget.initialPins, widget.initialPins)) {
      setState(() {
        _pins = widget.initialPins;
      });
    }

    // Update selected pinner if it changes
    if (oldWidget.selectedPinner != widget.selectedPinner) {
      setState(() {
        _selectedPinner = widget.selectedPinner;
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
    _imagePinPointController.loadImageAspectRatio(widget.imageSource, (info) {
      try {
        if (mounted) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        }
      } catch (e) {
        log('Error loading image dimensions: $e');
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
    if (_selectedPinner == null) return;

    _imagePinPointController.onTapDown(details, widget.imagePinPointKey,
        (adjustedPosition) {
      setState(() {
        _pins = [
          ..._pins,
          Pinner(
            position: adjustedPosition,
            widget: _selectedPinner!.widget,
          )
        ];
        widget.onPinsUpdated.call(_pins);
      });
    }, _imageWidth, _imageHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: _imageWidth / _imageHeight,
        child: RepaintBoundary(
          key: widget.imagePinPointKey,
          child: GestureDetector(
            onTapDown: _addPin,
            child: Stack(
              children: [
                _buildImage(),
                if (_pins.isNotEmpty)
                  ..._pins.map((pin) {
                    return Positioned(
                      left: pin.position.dx,
                      top: pin.position.dy,
                      child: _PinCenterer(
                        child: Material(
                          color: Colors.transparent,
                          child: pin.widget,
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
      return ImageUtils.isNetworkImage(widget.imageSource)
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
      log('${LogMessages.errorBuildingImage}: $e');
      return const Center(child: Icon(Icons.error));
    }
  }
}

/// A widget that centers its child at the origin point
///
/// This widget ensures that pins are properly centered at their exact coordinates
/// by measuring the child widget's size and applying an appropriate offset.
class _PinCenterer extends StatefulWidget {
  /// The widget to be centered (typically a pin marker)
  final Widget child;

  /// Creates a widget that centers its child at the origin point
  const _PinCenterer({
    required this.child,
  });

  @override
  State<_PinCenterer> createState() => _PinCentererState();
}

/// State for the PinCenterer that handles measurement and positioning
class _PinCentererState extends State<_PinCenterer> {
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
