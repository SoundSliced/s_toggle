# s_toggle

A Flutter package providing a customizable animated toggle widget.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  s_toggle: ^0.0.1
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
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool _isToggled = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SToggle(
            size: 80.0,
            onColor: Colors.green,
            offColor: Colors.red,
            value: _isToggled,
            onChange: (value) {
              setState(() {
                _isToggled = value;
              });
            },
          ),
          SizedBox(height: 20),
          Text('Toggle is ${_isToggled ? 'ON' : 'OFF'}'),
        ],
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

See the `example/` directory for a complete Flutter app demonstrating the usage of the s_toggle package.

## License

This package is licensed under the MIT License. See the LICENSE file for details.

## Repository

https://github.com/SoundSliced/s_toggle
