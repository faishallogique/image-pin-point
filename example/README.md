# Image Pin Point Demo

A comprehensive Flutter demo showcasing the `image_pin_point` package functionality with a creative and modern UI.

## Features

- 🖼️ **Multiple Image Selection**: Choose from a variety of sample images
- 📌 **Custom Pin Styles**: 5 different pin styles with unique colors and icons
- 🎨 **Interactive UI**: Modern Material Design 3 interface
- 💾 **Save Functionality**: Save images with pins to device gallery
- 🧹 **Clear Pins**: Easy pin removal with a single tap
- 📱 **Cross-Platform**: Works on both iOS and Android

## Screenshots

The app features:
- Image selection carousel at the top
- Main image area with interactive pin placement
- Pin style options at the bottom
- Clear and save buttons

## Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- iOS Simulator or Android Emulator

### Installation

1. Clone this repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. **Select an Image**: Tap on any image in the carousel at the top
2. **Choose a Pin Style**: Select one of the colored pin styles (A, B, C, D, E)
3. **Add Pins**: Tap anywhere on the image to place pins
4. **Clear Pins**: Use the clear button to remove all pins
5. **Save Image**: Use the save button to save the image with pins to your device

## Pin Styles

- **A** (Red): Location pin with location icon
- **B** (Blue): Star pin with star icon
- **C** (Green): Heart pin with favorite icon
- **D** (Orange): Thumbs up pin with thumb up icon
- **E** (Purple): Diamond pin with diamond icon

## Platform Configuration

### Android

The following permissions are already configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### iOS

The following permissions are already configured in `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to your photo library to save images.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to save images.</string>
```

## Dependencies

- `image_pin_point: ^0.0.2` - Main package for image pin functionality
- `flutter` - Flutter framework

## Project Structure

```
lib/
├── main.dart                 # Main application file with demo implementation
android/
├── app/src/main/
│   └── AndroidManifest.xml   # Android permissions configuration
ios/
├── Runner/
│   └── Info.plist           # iOS permissions configuration
```

## Key Features Implemented

1. **ImagePinPointContainer**: Main widget for displaying images with pins
2. **ImagePinPointOptions**: Widget for pin style selection and actions
3. **Custom Pin Styles**: Beautiful custom pin designs with shadows and labels
4. **Error Handling**: Proper error handling for save operations
5. **State Management**: Efficient state management with setState
6. **Async Operations**: Proper async context handling

## Contributing

Feel free to contribute to this demo by:
- Adding new pin styles
- Improving the UI design
- Adding new features
- Fixing bugs

## License

This project is licensed under the MIT License.
