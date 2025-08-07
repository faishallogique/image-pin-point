import 'package:flutter/material.dart';
import 'package:image_pin_point/image_pin_point.dart';

/// The main entry point of the Image Pin Point Demo application.
///
/// Initializes and runs the application with the [ImagePinPointDemoApp] as the root widget.
void main() {
  runApp(const ImagePinPointDemoApp());
}

/// Root application widget for the Image Pin Point Demo.
///
/// Configures the MaterialApp with a custom theme and sets up the main demo screen.
/// Uses Material Design 3 with a blue color scheme and handles edge-to-edge display.
///
/// Example:
/// ```dart
/// void main() {
///   runApp(const ImagePinPointDemoApp());
/// }
/// ```
class ImagePinPointDemoApp extends StatelessWidget {
  const ImagePinPointDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Pin Point Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      //handles edge-to-edge display with SafeArea
      builder: (_, child) => SafeArea(top: false, bottom: true, child: child!),
      home: const ImagePinPointDemoScreen(),
    );
  }
}

/// Main demo screen that showcases the image_pin_point package functionality.
///
/// Provides a complete interface for:
/// - Selecting from multiple sample images
/// - Adding custom pins to images
/// - Managing pin styles and positions
/// - Saving images with pins to device gallery
///
/// The screen is divided into three main sections:
/// 1. Image selection carousel at the top
/// 2. Main interactive image area in the center
/// 3. Pin style options and action buttons at the bottom
class ImagePinPointDemoScreen extends StatefulWidget {
  const ImagePinPointDemoScreen({super.key});

  @override
  State<ImagePinPointDemoScreen> createState() =>
      _ImagePinPointDemoScreenState();
}

/// State management for the [ImagePinPointDemoScreen].
///
/// Manages the application state including:
/// - Currently selected image
/// - Pins placed on the image
/// - Selected pin style for new pins
/// - UI state and interactions
///
/// Key features:
/// - Efficient state management with minimal rebuilds
/// - Proper async operation handling
/// - Error handling for save operations
/// - Clean separation of concerns
class _ImagePinPointDemoScreenState extends State<ImagePinPointDemoScreen> {
  /// Global key for referencing the image widget during save operations.
  final GlobalKey _imageWidgetKey = GlobalKey();

  /// List of pins currently placed on the image.
  List<Pinner> _currentPins = [];

  /// Currently selected pin style for new pin placement.
  Pinner? _selectedPinStyle;

  /// Currently selected image URL.
  String? _selectedImageUrl;

  /// Sample images available for selection.
  ///
  /// Uses Picsum Photos for demonstration purposes.
  /// In a real application, these would be replaced with actual image assets.
  static const List<String> _sampleImageUrls = [
    'https://picsum.photos/800/600?random=1',
    'https://picsum.photos/800/600?random=2',
    'https://picsum.photos/800/600?random=3',
  ];

  @override
  void initState() {
    super.initState();
    _selectedImageUrl = _sampleImageUrls.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Pin Point Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: Column(
        children: [
          _buildImageSelectionSection(),
          _buildMainImageArea(),
          _buildPinStyleOptionsSection(),
        ],
      ),
    );
  }

  /// Builds the image selection carousel section.
  ///
  /// Displays a horizontal scrollable list of sample images that users can select.
  /// Shows visual feedback for the currently selected image.
  Widget _buildImageSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Image:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sampleImageUrls.length,
              itemBuilder: (context, index) => _buildImageSelectionItem(index),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an individual image selection item.
  ///
  /// Creates a selectable image thumbnail with visual feedback for selection state.
  Widget _buildImageSelectionItem(int index) {
    final imageUrl = _sampleImageUrls[index];
    final isSelected = _selectedImageUrl == imageUrl;

    return GestureDetector(
      onTap: () => _onImageSelected(imageUrl),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main interactive image area.
  ///
  /// Displays the selected image with the [ImagePinPointContainer] for pin placement.
  /// Handles the case when no image is selected.
  Widget _buildMainImageArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _selectedImageUrl != null
            ? ImagePinPointContainer(
                imagePinPointKey: _imageWidgetKey,
                imageSource: _selectedImageUrl!,
                pinsOnTheImage: _currentPins,
                selectedPinStyle: _selectedPinStyle,
                onPinsUpdated: _onPinsUpdated,
              )
            : const Center(child: Text('No image selected')),
      ),
    );
  }

  /// Builds the pin style options and action buttons section.
  ///
  /// Displays available pin styles and utility buttons for clearing pins and saving images.
  Widget _buildPinStyleOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pin Styles:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ImagePinPointOptions(
            pinStyleOptions: [
              ..._buildPinStyleOptions(),
              _buildClearPinsButton(),
              _buildSaveImageButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the list of available pin style options.
  ///
  /// Returns a list of custom pin widgets with different colors, icons, and labels.
  List<Widget> _buildPinStyleOptions() {
    const pinConfigurations = [
      _PinConfiguration('A', Colors.red, Icons.location_on),
      _PinConfiguration('B', Colors.blue, Icons.star),
      _PinConfiguration('C', Colors.green, Icons.favorite),
      _PinConfiguration('D', Colors.orange, Icons.thumb_up),
      _PinConfiguration('E', Colors.purple, Icons.diamond),
    ];

    return pinConfigurations
        .map((config) => _buildCustomPinStyle(config))
        .toList();
  }

  /// Builds a custom pin style widget.
  ///
  /// Creates a selectable pin style with a colored background, icon, and label.
  /// Includes shadow effects and visual feedback for selection.
  Widget _buildCustomPinStyle(_PinConfiguration config) {
    final pinWidget = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: config.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(child: Icon(config.icon, color: Colors.white, size: 20)),
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                config.label,
                style: TextStyle(
                  color: config.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onPinStyleSelected(pinWidget),
        child: pinWidget,
      ),
    );
  }

  /// Builds the clear pins button.
  ///
  /// Returns a button that clears all pins from the current image.
  Widget _buildClearPinsButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: IconButton(
        onPressed: _clearAllPins,
        style: IconButton.styleFrom(
          backgroundColor: Colors.red[100],
          foregroundColor: Colors.red[700],
        ),
        icon: const Icon(Icons.clear_all),
        tooltip: 'Clear all pins',
      ),
    );
  }

  /// Builds the save image button.
  ///
  /// Returns a button that saves the current image with pins to the device gallery.
  Widget _buildSaveImageButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: IconButton(
        onPressed: _saveImageWithPins,
        style: IconButton.styleFrom(
          backgroundColor: Colors.green[100],
          foregroundColor: Colors.green[700],
        ),
        icon: const Icon(Icons.save),
        tooltip: 'Save image with pins',
      ),
    );
  }

  /// Handles image selection from the carousel.
  ///
  /// Updates the selected image and clears existing pins when a new image is chosen.
  void _onImageSelected(String imageUrl) {
    setState(() {
      _selectedImageUrl = imageUrl;
      _currentPins.clear();
    });
  }

  /// Handles pin updates from the [ImagePinPointContainer].
  ///
  /// Updates the current pins list when pins are added, moved, or removed.
  void _onPinsUpdated(List<Pinner> updatedPins) {
    setState(() {
      _currentPins = updatedPins;
    });
  }

  /// Handles pin style selection.
  ///
  /// Updates the selected pin style for new pin placement.
  void _onPinStyleSelected(Widget pinWidget) {
    setState(() {
      _selectedPinStyle = Pinner(
        position: const Offset(0, 0),
        widget: pinWidget,
      );
    });
  }

  /// Clears all pins from the current image.
  ///
  /// Removes all pins and updates the UI state.
  void _clearAllPins() {
    setState(() {
      _currentPins.clear();
    });
  }

  /// Saves the current image with pins to the device gallery.
  ///
  /// Performs validation, handles async operations, and provides user feedback.
  /// Shows appropriate success/error messages based on the operation result.
  Future<void> _saveImageWithPins() async {
    if (_currentPins.isEmpty) {
      _showSnackBar(
        'Add some pins before saving!',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final OperationResult result = await ImagePinPoint.saveImage(
        _imageWidgetKey,
        skipSaveToGallery: false,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        _showSnackBar(
          'Image saved successfully!\nPath: ${result.filePath}',
          backgroundColor: Colors.green,
        );
      } else {
        _showSnackBar('Failed to save image', backgroundColor: Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error saving image: $e', backgroundColor: Colors.red);
    }
  }

  /// Shows a snack bar with the given message and background color.
  ///
  /// Helper method for displaying user feedback messages.
  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}

/// Configuration class for pin styles.
///
/// Encapsulates the properties needed to create a custom pin style:
/// - [label]: The text label displayed on the pin
/// - [color]: The background color of the pin
/// - [icon]: The icon displayed in the center of the pin
class _PinConfiguration {
  const _PinConfiguration(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}
