import 'dart:async';
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
/// - Show pins at specific coordinates on the image
/// - Add new pins by tapping on the image after selecting a pin style
/// - Maintain proper aspect ratio of the original image
/// - Notify parent widgets when pins are added or changed
class ImagePinPointContainer extends StatefulWidget {
  /// Creates an image container that supports pin placement
  ///
  /// Parameters:
  /// - [imageSource]: File path or URL to the image (required)
  /// - [pinsOnTheImage]: List of pins to display on the image
  /// - [selectedPinStyle]: Currently selected pin style to add new pin on the image
  /// - [onPinsUpdated]: Callback when pins on the image are added
  /// - [imagePinPointKey]: Key used for capturing the widget state as an image
  const ImagePinPointContainer({
    super.key,
    this.pinsOnTheImage = const [],
    required this.imageSource,
    this.selectedPinStyle,
    this.onPinsUpdated,
    required this.imagePinPointKey,
    this.onFirstLoad,
    this.onPinsEditingComplete,
  });

  /// list of pins to display on the image
  /// These pins will be shown when the widget loads
  final List<Pinner> pinsOnTheImage;

  /// Source file path/URL of the image to display
  /// Can be either a network URL or a local file path
  final String imageSource;

  /// Currently selected pin style and properties
  /// When set, defines the appearance of new pins added to the image
  final Pinner? selectedPinStyle;

  /// Callback triggered when pins are added/modified
  /// Provides the updated list of all pins on the image
  final void Function(List<Pinner> pins)? onPinsUpdated;

  /// Key used for capturing the widget state as an image
  /// This is required for the image saving functionality
  final GlobalKey imagePinPointKey;

  /// Callback triggered when the widget is first loaded
  /// This is useful for initializing data or triggering actions when the widget appears
  final void Function()? onFirstLoad;

  /// Callback triggered when the user finishes adding pins to the image
  ///
  /// This is similar to onEditingComplete in TextField - it's called when the user
  /// has finished interacting with the pins and no new pins are being added.
  /// This is useful for performing actions only after the user has completed
  /// their pin placement, rather than during each pin update.
  final void Function(List<Pinner> pins)? onPinsEditingComplete;

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
  /// Updated when new pins are added or when pinsOnTheImage changes
  late List<Pinner> _pins;

  /// Width of the loaded image in pixels
  late double _imageWidth;

  /// Height of the loaded image in pixels
  late double _imageHeight;

  /// Currently selected pin for adding to image
  /// Determines the appearance of new pins when tapping the image
  Pinner? _selectedPinStyle;

  /// Timer to detect when user has finished adding pins
  Timer? _editingCompleteTimer;

  /// Duration to wait before considering pin editing complete
  static const Duration _editingCompleteDelay = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    _imageWidth = 1.0;
    _imageHeight = 1.0;
    _pins = widget.pinsOnTheImage;
    _selectedPinStyle = widget.selectedPinStyle;

    _updateImageDimensions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFirstLoad?.call();
    });
  }

  @override
  void dispose() {
    _editingCompleteTimer?.cancel();
    super.dispose();
  }

  /// Resets the editing complete timer
  /// Called each time a pin is added to detect when user stops adding pins
  void _resetEditingCompleteTimer(List<Pinner> pins) {
    _editingCompleteTimer?.cancel();
    if (widget.onPinsEditingComplete != null) {
      _editingCompleteTimer = Timer(_editingCompleteDelay, () {
        widget.onPinsEditingComplete?.call(pins);
      });
    }
  }

  @override
  void didUpdateWidget(ImagePinPointContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset pins if image source changes
    if (oldWidget.imageSource != widget.imageSource) {
      _updateImageDimensions();
      setState(() {
        _pins = [];
        _selectedPinStyle = null;
      });
    }

    // Update pins if pins list changes
    if (!listEquals(oldWidget.pinsOnTheImage, widget.pinsOnTheImage)) {
      setState(() {
        _pins = widget.pinsOnTheImage;
      });
    }

    // Update selected pin if it changes
    if (oldWidget.selectedPinStyle != widget.selectedPinStyle) {
      setState(() {
        _selectedPinStyle = widget.selectedPinStyle;
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
  void _updateImageDimensions() async {
    final imageInfo = await ImageUtils.loadImageAspectRatio(widget.imageSource);

    try {
      if (mounted) {
        setState(() {
          _imageWidth = imageInfo.image.width.toDouble();
          _imageHeight = imageInfo.image.height.toDouble();
        });
      }
    } catch (e) {
      log('${LogMessages.errorLoadingImageDimensions}: $e');
    }
  }

  /// Adds a new pin at the tapped location
  ///
  /// This method:
  /// - Checks if a pin type is selected
  /// - Converts tap coordinates to image coordinates
  /// - Creates a new pin at the adjusted position
  /// - Updates the pins list and notifies listeners
  void _addPin(TapDownDetails details) {
    if (_selectedPinStyle == null) return;

    onTapDown(details, widget.imagePinPointKey, (adjustedPosition) {
      try {
        setState(() {
          _pins = [
            ..._pins,
            Pinner(
              position: adjustedPosition,
              widget: _selectedPinStyle!.widget,
            )
          ];
          widget.onPinsUpdated?.call(_pins);
          _resetEditingCompleteTimer(
              _pins); // Reset timer when a new pin is added
        });
      } catch (e) {
        log('${LogMessages.errorAddingPin}: $e');
      }
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
