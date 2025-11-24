# s_toggle

A Flutter package providing a customizable animated toggle widget with smooth elastic animations and bounce effects.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  s_toggle: ^1.0.2
```

Or for the latest version:

```yaml
dependencies:
  s_toggle:
    git: https://github.com/SoundSliced/s_toggle.git
```

## Usage

Import the package:

```dart
import 'package:s_toggle/s_toggle.dart';
```

### Basic Example

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _toggleValue = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('s_toggle Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Toggle the switch:',
            ),
            const SizedBox(height: 20),
            SToggle(
              size: 80.0,
              onColor: Colors.green,
              offColor: Colors.red,
              value: _toggleValue,
              onChange: (value) {
                setState(() {
                  _toggleValue = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Toggle is ${_toggleValue ? 'ON' : 'OFF'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
```

### Advanced Customization

```dart
SToggle(
  size: 100.0,
  onColor: Colors.blueAccent,
  offColor: Colors.grey,
  value: _toggleValue,
  animationDuration: Duration(milliseconds: 500), // Custom animation speed
  onChange: (value) {
    // Handle state change
    print('Toggle changed to: $value');
    setState(() => _toggleValue = value);
  },
)
```

## Features

- **Customizable Design**: Easily adjust size, colors, and visual appearance
- **Smooth Animations**: Elastic bounce animation with customizable duration (default 700ms)
- **State Management**: Supports both programmatic and interactive state changes
- **Callback Support**: onChange callback for reacting to toggle state changes
- **Efficient Rendering**: Uses CustomPaint for optimal performance
- **Flexible Integration**: Works seamlessly with Flutter's widget system

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `size` | `double` | `60.0` | The size of the toggle (width = size, height = size / 2) |
| `onColor` | `Color` | `Colors.white` | Color when the toggle is in the "on" state |
| `offColor` | `Color` | `Colors.black87` | Color when the toggle is in the "off" state |
| `value` | `bool` | `false` | Initial state of the toggle |
| `animationDuration` | `Duration?` | `700ms` | Duration of the animation transition |
| `onChange` | `Function(bool value)?` | `null` | Callback function called when the state changes |

## Example

The `example/` directory contains a complete Flutter application demonstrating the s_toggle package. The example app features:

- A clean Material Design interface with an AppBar
- A centered toggle switch with custom colors (green for ON, red for OFF)
- Real-time state display showing whether the toggle is ON or OFF
- Demonstrates proper state management with setState
- Shows how to use the onChange callback effectively

To run the example:

```bash
cd example
flutter run
```

The example demonstrates best practices for integrating s_toggle into your Flutter applications, including:
- Proper widget composition
- State management patterns
- Callback handling
- UI/UX considerations

## License

This package is licensed under the MIT License. See the LICENSE file for details.

## Repository

https://github.com/SoundSliced/s_toggle
