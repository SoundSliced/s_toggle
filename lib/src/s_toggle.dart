import 'package:flutter/material.dart';
import 'package:soundsliced_dart_extensions/soundsliced_dart_extensions.dart';
import 'package:soundsliced_tween_animation_builder/soundsliced_tween_animation_builder.dart';

// ignore: must_be_immutable
class SToggle extends StatefulWidget {
  /// width and height of widget.
  /// width = size,height = size / 2.
  late double _width, _height;

  /// size of widget.
  final double size;

  /// onColor is color when widget switched on,
  /// default value is: [Colors.white].
  /// offColor is color when widget switched off,
  /// default value is: [Colors.black].
  final Color onColor, offColor;

  /// status of widget, if value == true widget will switched on else
  /// switched off
  final bool value;

  final Duration? animationDuration;

  /// when change status of widget like switch off or switch on [onChange] will
  /// call and passed new [value]
  final Function(bool value)? onChange;

  SToggle({
    super.key,
    this.size = 60.0,
    this.onColor = Colors.white,
    this.offColor = Colors.black87,
    this.value = false,
    this.animationDuration,
    this.onChange,
  }) {
    _width = size;
    _height = size / 2;
  }

  @override
  SToggleState createState() => SToggleState();
}

class SToggleState extends State<SToggle> {
  /// sate of widget that can be switched on or switched off.
  late bool value;

  /// Target value for animation
  late bool _targetValue;

  /// Animation trigger key
  int _animationKey = 0;

  /// Track which side is animating
  bool _isAnimating = false;

  @override
  void initState() {
    value = widget.value;
    _targetValue = widget.value;
    super.initState();
  }

  // change state of widget when clicked on widget.
  void changeState() {
    if (!_isAnimating) {
      _targetValue = !value;
      _isAnimating = true;
      _animationKey++;

      // Call onChange
      if (widget.onChange != null) widget.onChange!(_targetValue);
    }
  }

  @override
  void didUpdateWidget(SToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _targetValue = widget.value;
      if (!_isAnimating) {
        _isAnimating = true;
        _animationKey++;
      }
      // Note: onChange is not called for programmatic changes, only for user interactions
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: changeState,
      child: Container(
        width: widget._width,
        height: widget._height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10000.0))),
        child: MyTweenAnimationBuilder<double>(
          key: ValueKey(_animationKey),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration:
              widget.animationDuration ?? const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          onEnd: () {
            if (mounted) {
              setState(() {
                value = _targetValue;
                _isAnimating = false;
              });
            }
          },
          builder: (context, progress, child) {
            // Calculate radii based on animation progress
            double rightRadius, leftRadius;
            bool displayValue;

            if (_targetValue) {
              // Switching to ON
              if (progress < 0.43) {
                // Phase 1: Left circle expands (0.0 -> 0.43)
                final phase1Progress = progress / 0.43;
                leftRadius = widget._height * .18 +
                    (widget._width - widget._height * .18) * phase1Progress;
                rightRadius = widget._width * 2;
                displayValue = false;
              } else {
                // Phase 2: Right circle appears with bounce (0.43 -> 1.0)
                final phase2Progress = (progress - 0.43) / 0.57;
                rightRadius = widget._width * 2;
                // Elastic bounce effect
                leftRadius = widget._height * .18 * _elasticOut(phase2Progress);
                displayValue = true;
              }
            } else {
              // Switching to OFF
              if (progress < 0.43) {
                // Phase 1: Right circle expands (0.0 -> 0.43)
                final phase1Progress = progress / 0.43;
                rightRadius = widget._height * .18 +
                    (widget._width - widget._height * .18) * phase1Progress;
                leftRadius = widget._width * 2;
                displayValue = true;
              } else {
                // Phase 2: Left circle appears with bounce (0.43 -> 1.0)
                final phase2Progress = (progress - 0.43) / 0.57;
                leftRadius = widget._width * 2;
                // Elastic bounce effect
                rightRadius =
                    widget._height * .18 * _elasticOut(phase2Progress);
                displayValue = false;
              }
            }

            return CustomPaint(
              painter: _ProfileCardPainter(
                offColor: widget.offColor,
                onColor: widget.onColor,
                leftRadius: leftRadius,
                rightRadius: rightRadius,
                value: displayValue,
              ),
            );
          },
        ),
      ),
    );
  }

  // Elastic out easing function to mimic Curves.elasticOut
  double _elasticOut(double t) {
    const double p = 0.3;
    if (t == 0.0 || t == 1.0) return t;
    return 1.0 + (2.0 * (t - 1.0) * (t - 1.0) * ((p + 1) * (t - 1.0) + p));
  }
}

class _ProfileCardPainter extends CustomPainter {
  /// Left circle radius.
  late double rightRadius;

  /// Right circle radius.
  late double leftRadius;

  /// State of widget.
  late bool value;

  /// Color when widget is on
  late Color onColor;

  /// Color when widget is off
  late Color offColor;

  _ProfileCardPainter(
      {required this.rightRadius,
      required this.leftRadius,
      required this.value,
      required this.onColor,
      required this.offColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (value) {
      var paint = Paint()
        ..color = onColor
        ..strokeWidth = 18;
      Offset center = Offset((size.width / 2) / 2, size.height / 2);
      canvas.drawCircle(center, leftRadius, paint);

      paint.color = offColor.lighten(0.8);
      center =
          Offset(((size.width / 2) / 2) + (size.width / 2), size.height / 2);
      canvas.drawCircle(center, rightRadius, paint);
    } else {
      var paint = Paint()..strokeWidth = 18;
      Offset center;

      paint.color = offColor;
      center =
          Offset(((size.width / 2) / 2) + (size.width / 2), size.height / 2);
      canvas.drawCircle(center, rightRadius, paint);

      paint.color = onColor;
      center = Offset((size.width / 2) / 2, size.height / 2);
      canvas.drawCircle(center, leftRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_ProfileCardPainter oldDelegate) {
    return true;
  }
}
