# Image Pin Point

A Flutter package that allows you to add interactive pins to images with customizable styles and positions.

---

## Features

- Add pins to specific points on images
- Customize pin appearance with your own widgets
- Support for both network and local images
- Save images with pins as `png` files 

---

## Getting Started

Add the package to your `pubspec.yaml`:
```yaml
dependencies:
  image_pin_point: ^0.0.1
```

---

## Platform Configuration
This package use https://pub.dev/packages/saver_gallery to save image into the phone gallery.

for iOS add this to `Info.plist` file:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to your photo library to save images.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to save images.</string>
```

for Android add this to `AndroidManifest.xml` file:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage" />
<!-- Required if skipIfExists is set to true -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

---

## Usage

```dart
import 'package:image_pin_point/image_pin_point.dart';

...
// declare a key to ImagePinPointContainer widget
final imageKey = GlobalKey();

// declare a list of pins to display on the image
List<Pinner>> pinsOnTheImage = [];

// currently selected pin style (from your own widgets) to be added on the image
Pinner? selectedPinStyle = null;

// a placeholder widget that displays your image and allows adding pins at specific points
ImagePinPointContainer(
    imagePinPointKey: imageKey,
    imageSource: imageSource, //can be filepath from local file or network url
    pinsOnTheImage: pinsOnTheImage,
    selectedPinStyle: selectedPinStyle,
    onPinsUpdated: (pins) {
        //update the pinsOnTheImage
        setState(() {
           pinsOnTheImage = pins;
        });
    }
)
...

```

an optional placeholder widget of your pin style options  
```dart
import 'package:image_pin_point/image_pin_point.dart';

...
ImagePinPointOptions(
    pinStyleOptions: [
    //pin style options to be added on the image
    ...List.generate(4, (index) {
        final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.orange,
        ];

        final labels = ['A', 'B', 'C', 'D'];

        return _buildButton(labels[index], colors[index],
            (selectedPinner) {
                selectedPinStyle
            //update the selected pin style
            setState(() {
                selectedPinStyle = selectedPinner;
            });
        });
    }),
    // a widget to clear existing pins on the image
    IconButton(
        onPressed: () {
            //clear existing pins on the image
            setState(() {
                pinsOnTheImage.clear();
            });
        },
        icon: const Icon(Icons.clear),
    ),
    // a widget to save the image as png file to phone gallery or just use filePath result from the return value
    IconButton(
        onPressed: () async {
            //pass the imageKey you previously declare and set on the ImagePinPointContainer
            final OperationResult result = await ImagePinPoint.saveImage(imageKey,
                skipSaveToGallery: false);
            print(result.filePath);
        },
        icon: const Icon(Icons.save),
    ),
    ],
)

// your custom widget
Widget _buildButton(String label, Color color,
    final Function(Pinner selectedPinner) onSelectedButtonTapped) {
final child = Ink(
    width: 32,
    height: 32,
    decoration:
        BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Center(
        child: Text(label, style: const TextStyle(color: Colors.white))),
);

return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
        onSelectedButtonTapped
            .call(Pinner(position: const Offset(0, 0), widget: child));
    },
    child: child);
}
...

```
