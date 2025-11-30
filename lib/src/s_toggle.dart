import 'package:flutter/material.dart';
// Debug logging removed for production stability
import 'package:flutter/foundation.dart';
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

  /// Sensitivity factor for drag to visual mapping (0.0..1.0). Lower = less sensitive
  final double dragSensitivity;

  /// Smoothing (viscosity) for drag pointer to visual mapping: 0.0 = no smoothing, 1.0 = fully sticky
  /// Applies when user drags to make the small circle feel heavy/smooth. Default 0.1.
  final double dragSmoothing;

  /// Show debug overlay showing pointer and smoothed small circle positions. Only used in debug builds.
  final bool debugShowPointers;

  /// status of widget, if value == true widget will switched on else
  /// switched off
  final bool value;

  final Duration? animationDuration;

  /// when change status of widget like switch off or switch on [onChange] will
  /// call and passed new [value]
  final Function(bool value)? onChange;

  /// Animate a faint background tint that blends between offColor and onColor.
  /// When true, a rounded-rect background is drawn behind circles, smoothly
  /// lerping from [offColor] to [onColor] following the toggle's visual state.
  final bool animateBackground;

  /// Opacity of the animated background tint (0.0..1.0). Default 0.15 for a faint look.
  final double backgroundOpacity;

  /// Outer border around the whole widget (rounded rectangle). Width 0 disables.
  final double borderWidth;
  final Color? borderColor; // if null, derived from background tint (darker)

  /// Border around the little circle. Width 0 disables.
  final double littleBorderWidth;
  final Color?
      littleBorderColor; // if null, derived from little fill color (darker)

  /// Shadow for the little circle.
  /// Set blurSigma to 0 to disable shadow.
  final double littleShadowBlurSigma; // e.g. 6.0 for soft shadow
  final Offset littleShadowOffset; // e.g. Offset(0, 2)
  final Color littleShadowColor; // e.g. Colors.black.withOpacity(0.25)

  SToggle({
    super.key,
    this.size = 60.0,
    this.onColor = Colors.white,
    this.offColor = Colors.black87,
    this.value = false,
    this.animationDuration,
    this.onChange,
    this.dragSensitivity = 0.85,
    this.dragSmoothing = 0.1,
    this.debugShowPointers = false,
    this.animateBackground = true,
    this.backgroundOpacity = 0.15,
    this.borderWidth = 1.0,
    this.borderColor,
    this.littleBorderWidth = 0.0,
    this.littleBorderColor,
    this.littleShadowBlurSigma = 6.0,
    this.littleShadowOffset = const Offset(0, 2),
    this.littleShadowColor = const Color(0x40000000),
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

  /// Drag accumulation for horizontal gestures
  double _dragDelta = 0.0;

  /// Drag start X (local) used to compute delta precisely
  double? _dragStartX;

  /// Drag start small circle X (center) used to align pointer mapping
  double? _dragStartSmallX;

  /// Pointer X at start of drag
  // double? _dragStartPointerX; // not used

  /// Last observed pointer X local to widget, for debugging comparisons
  double? _lastPointerX;

  /// Live drag visualization flag
  bool _isDragging = false;

  /// Normalized drag progress in range [-1.0, 1.0]
  double _dragProgress = 0.0;

  /// Raw drag progress computed directly from pointer (not smoothed)
  double _rawDragProgress = 0.0;

  /// Smoothed drag progress used for visuals during drag
  double _smoothedDragProgress = 0.0;

  /// Smoothed small circle center X (pixels) used for visuals
  double? _smoothedSmallX;

  /// Resume tween from this progress after drag end
  double? _resumeFromProgress;
  bool _isResuming = false;
  double _resumeToEnd = 1.0;
  // (duplicate removed)
  // (duplicate removed)

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
    // No inline debug drawing here — painting is handled in CustomPainter
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    // Reset drag accumulation at start
    _dragDelta = 0.0;
    _dragStartX = details.localPosition.dx;
    // _dragStartPointerX = details.localPosition.dx; // not used
    _smoothedDragProgress = _dragProgress;
    // initialize smoothed small X to current small circle center
    final leftX = widget._width / 4.0;
    final rightX = widget._width * 3.0 / 4.0;
    _smoothedSmallX = value ? rightX : leftX;
    // _dragStartSmallX set is not needed yet; pointer-based mapping is used
    _isDragging = true;
    _dragProgress = 0.0;
    _lastPointerX = details.localPosition.dx;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Compute horizontal drag using start X to avoid cumulative drift/jump
    final double dxLocal = details.localPosition.dx;
    if (_dragStartX != null) {
      _dragDelta = dxLocal - _dragStartX!;
    }
    // Precompute geometry constants
    final double leftX = widget._width * 0.25;
    final double rightX = widget._width * 0.75;
    final double centerSpan = (rightX - leftX);
    // Anchored mapping with sensitivity
    final double mappingFactor = widget.dragSensitivity.clamp(0.1, 1.0);
    double desiredSmallX = _dragStartSmallX ?? (value ? rightX : leftX);
    final double pointerX = dxLocal.clamp(leftX, rightX);
    desiredSmallX = (desiredSmallX + (pointerX - desiredSmallX) * mappingFactor)
        .clamp(leftX, rightX);
    final double tRaw = ((desiredSmallX - leftX) / centerSpan).clamp(0.0, 1.0);
    // Map relative to the start side so mappingFactor reduces responsiveness
    // If starting ON (right), raw progress is negative as pointer moves left
    if (value) {
      _rawDragProgress = (tRaw - 1.0).clamp(-1.0, 0.0);
      _dragProgress = _rawDragProgress;
    } else {
      _rawDragProgress = tRaw.clamp(0.0, 1.0);
      _dragProgress = _rawDragProgress;
    }
    // Apply smoothing to visual progress
    final double smoothAlpha = (1.0 - widget.dragSmoothing.clamp(0.0, 1.0));
    // Smooth the small circle center and compute smoothed progress from it
    if (_smoothedSmallX != null) {
      _smoothedSmallX =
          _smoothedSmallX! + (desiredSmallX - _smoothedSmallX!) * smoothAlpha;
    } else {
      _smoothedSmallX = desiredSmallX;
    }
    final double tSmoothed =
        ((_smoothedSmallX! - leftX) / centerSpan).clamp(0.0, 1.0);
    if (value) {
      _smoothedDragProgress = (tSmoothed - 1.0).clamp(-1.0, 0.0);
    } else {
      _smoothedDragProgress = tSmoothed.clamp(0.0, 1.0);
    }
    // We are now using pointer-based mapping (tRaw) to compute _dragProgress above,
    // so we do not reassign it here.
    _lastPointerX = dxLocal;
    // Trigger repaint during drag only when visual progress changed materially
    // This reduces rebuild churn; tolerance prevents excessive setState calls.
    setState(() {});
    if (kDebugMode && widget.debugShowPointers) {
      final leftX = widget._width / 4.0;
      final rightX = widget._width * 3.0 / 4.0;
      final progressRight = _rawDragProgress > 0 ? _rawDragProgress : 0.0;
      final progressLeft = _rawDragProgress < 0 ? -_rawDragProgress : 0.0;
      final t = value ? (1.0 - progressLeft) : progressRight;
      final visualX = leftX + (rightX - leftX) * t;
      debugPrint(
          '[SToggle] debug dragUpdate pointerX=${_lastPointerX?.toStringAsFixed(1)} dx=${details.localPosition.dx.toStringAsFixed(1)} delta=${_dragDelta.toStringAsFixed(1)} raw=${_rawDragProgress.toStringAsFixed(3)} smoothed=${_smoothedDragProgress.toStringAsFixed(3)} t=${t.toStringAsFixed(3)} desiredSmall=${desiredSmallX.toStringAsFixed(1)} smoothedSmall=${_smoothedSmallX?.toStringAsFixed(1)} visualX=${visualX.toStringAsFixed(1)}');
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // End drag visualization
    final endDragProgress = _rawDragProgress;
    _isDragging = false;
    _dragProgress = 0.0;

    if (_isAnimating) {
      // Ignore drags during animation, reset accumulation
      _dragDelta = 0.0;
      return;
    }

    // Use progress-first thresholding to align with animation phases
    final endProgress = endDragProgress.abs().clamp(0.0, 1.0);
    const double progressCommitThreshold =
        0.43; // same as animation phase split
    final vx = details.primaryVelocity ?? 0.0;
    final baseThreshold = widget._width * 0.15; // 15% of width threshold
    // Reduce threshold when fast swipe (makes commit easier on quick flicks)
    final velocityFactor = (vx.abs() / 800.0).clamp(0.0, 1.0); // tuned constant
    final threshold = (baseThreshold * (1.0 - 0.5 * velocityFactor))
        .clamp(8.0, baseThreshold);

    // Respect text direction: in RTL, positive dx should map to OFF
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final delta = _dragDelta;
    final desired =
        isRTL ? (delta > 0 ? false : true) : (delta > 0 ? true : false);

    // If we've progressed past the animation phase split, commit immediately
    if (endProgress >= progressCommitThreshold || delta.abs() >= threshold) {
      if (desired != value) {
        // Resume animation from current drag position to completion
        final d = endProgress; // normalized progress
        setState(() {
          _targetValue = desired;
          _resumeFromProgress = d;
          _isResuming = true;
          _resumeToEnd = 1.0;
          _isAnimating = true;
          _animationKey++;
        });
        if (widget.onChange != null) widget.onChange!(_targetValue);
      }
    } else {
      // Below threshold: revert to current state from drag position.
      // Resume the tween from the visual background mix back to the original side.
      final d = endDragProgress.abs().clamp(0.0, 1.0);
      setState(() {
        _targetValue = value; // keep current state
        // Map from current backgroundMix to tween progress start:
        // During drag, backgroundMix = value ? (1 - d) : d.
        // For animation builder:
        //  - If targetValue==true (ON), backgroundMix = progress.
        //  - If targetValue==false (OFF), backgroundMix = 1 - progress.
        // Therefore starting progress should be (1 - d) in both cases.
        _resumeFromProgress = (1.0 - d);
        _isResuming = true;
        // End progress: 1.0 returns to original side for both ON and OFF
        // (ON: mix = 1; OFF: mix = 1 - 1 = 0)
        _resumeToEnd = 1.0;
        _isAnimating = true;
        _animationKey++;
      });
    }
    // Reset drag delta after evaluation
    _dragDelta = 0.0;
    _dragStartX = null;
    // _dragStartPointerX = null; // not used
    _dragStartSmallX = null;
    _lastPointerX = null;
  }

  @override
  void didUpdateWidget(SToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // If our current internal value already matches the new prop, do not re-animate
      if (value == widget.value) {
        _targetValue = widget.value;
        // Ensure flags are reset to avoid stray animations later
        _isAnimating = false;
        _isResuming = false;
        _resumeFromProgress = null;
        _resumeToEnd = 1.0;
        return;
      }

      // Otherwise, programmatic change: animate to match new target only if not currently animating
      _targetValue = widget.value;
      if (!_isAnimating) {
        _isAnimating = true;
        _isResuming = false;
        _resumeFromProgress = null;
        _resumeToEnd = 1.0;
        _animationKey++;
      }
      // Note: onChange is not called for programmatic changes, only for user interactions
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: changeState,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Container(
        width: widget._width,
        height: widget._height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10000.0))),
        child: STweenAnimationBuilder<double>(
          key: ValueKey(_animationKey),
          // When not animating, freeze at final progress to avoid unintended replays
          tween: !_isAnimating
              ? Tween<double>(begin: 1.0, end: 1.0)
              : Tween<double>(
                  begin: _isResuming ? (_resumeFromProgress ?? 0.0) : 0.0,
                  end: _isResuming ? _resumeToEnd : 1.0,
                ),
          duration:
              widget.animationDuration ?? const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          onEnd: () {
            if (mounted) {
              setState(() {
                value = _targetValue;
                _isAnimating = false;
                _isResuming = false;
                _resumeFromProgress = null;
                _resumeToEnd = 1.0;
              });
            }
          },
          builder: (context, progress, child) {
            // Calculate radii based on animation progress
            double rightRadius, leftRadius;
            double littleRightRadius = 0.0, littleLeftRadius = 0.0;
            bool displayValue;
            // Background mix [0..1] used to lerp offColor->onColor
            double backgroundMix = value ? 1.0 : 0.0;

            // When dragging, drive animation by drag progress; otherwise, use tween progress
            if (_isDragging) {
              final d = _dragProgress.abs();
              if (value) {
                // Currently ON. Only react to leftward drags (progress < 0). Rightward drags keep ON.
                if (_dragProgress < 0) {
                  if (d < 0.43) {
                    final phase1Progress = d / 0.43;
                    rightRadius = widget._height * .18 +
                        (widget._width - widget._height * .18) * phase1Progress;
                    leftRadius = widget._width * 2;
                    littleLeftRadius = 0.0;
                    displayValue = true; // still visually ON in phase 1
                  } else {
                    final phase2Progress = (d - 0.43) / 0.57;
                    leftRadius = widget._width * 2;
                    rightRadius =
                        widget._height * .18 * _elasticOut(phase2Progress);
                    littleLeftRadius =
                        widget._height * .18 * _elasticOut(phase2Progress);
                    displayValue = false; // nearing OFF
                  }
                } else {
                  // Dragging right or stationary at ON. Keep ON stable.
                  rightRadius = widget._width * 2;
                  leftRadius = widget._height * .18;
                  littleRightRadius = widget._height * .18;
                  littleLeftRadius = 0.0;
                  displayValue = true;
                }
              } else {
                // Currently OFF. Only react to rightward drags (progress > 0). Leftward drags keep OFF.
                if (_dragProgress > 0) {
                  if (d < 0.43) {
                    final phase1Progress = d / 0.43;
                    leftRadius = widget._height * .18 +
                        (widget._width - widget._height * .18) * phase1Progress;
                    rightRadius = widget._width * 2;
                    littleRightRadius = 0.0;
                    displayValue = false; // still visually OFF in phase 1
                  } else {
                    final phase2Progress = (d - 0.43) / 0.57;
                    rightRadius = widget._width * 2;
                    leftRadius =
                        widget._height * .18 * _elasticOut(phase2Progress);
                    littleRightRadius =
                        widget._height * .18 * _elasticOut(phase2Progress);
                    displayValue = true; // nearing ON
                  }
                } else {
                  // Dragging left or stationary at OFF. Keep OFF stable.
                  leftRadius = widget._width * 2;
                  rightRadius = widget._height * .18;
                  littleLeftRadius = widget._height * .18;
                  littleRightRadius = 0.0;
                  displayValue = false;
                }
              }
              // During drag, derive background mix from smoothed visual progress
              final progressRight =
                  _smoothedDragProgress > 0 ? _smoothedDragProgress : 0.0;
              final progressLeft =
                  _smoothedDragProgress < 0 ? -_smoothedDragProgress : 0.0;
              backgroundMix = (value ? (1.0 - progressLeft) : progressRight)
                  .clamp(0.0, 1.0);
            } else {
              if (_targetValue) {
                // Switching to ON
                if (progress < 0.43) {
                  // Phase 1: Left circle expands (0.0 -> 0.43)
                  final phase1Progress = progress / 0.43;
                  leftRadius = widget._height * .18 +
                      (widget._width - widget._height * .18) * phase1Progress;
                  rightRadius = widget._width * 2;
                  // Little circle on RIGHT not visible yet
                  littleRightRadius = 0.0;
                  displayValue = false;
                } else {
                  // Phase 2: Right circle appears with bounce (0.43 -> 1.0)
                  final phase2Progress = (progress - 0.43) / 0.57;
                  rightRadius = widget._width * 2;
                  // Elastic bounce effect
                  leftRadius =
                      widget._height * .18 * _elasticOut(phase2Progress);
                  // Little circle on RIGHT grows in with bounce (slightly larger)
                  littleRightRadius =
                      widget._height * .22 * _elasticOut(phase2Progress);
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
                  // Little circle on LEFT not visible yet
                  littleLeftRadius = 0.0;
                  displayValue = true;
                } else {
                  // Phase 2: Left circle appears with bounce (0.43 -> 1.0)
                  final phase2Progress = (progress - 0.43) / 0.57;
                  leftRadius = widget._width * 2;
                  // Elastic bounce effect
                  rightRadius =
                      widget._height * .18 * _elasticOut(phase2Progress);
                  // Little circle on LEFT grows in with bounce (slightly larger)
                  littleLeftRadius =
                      widget._height * .22 * _elasticOut(phase2Progress);
                  displayValue = false;
                }
              }
              // When animating/idle, use tween progress for background mix
              backgroundMix =
                  (_targetValue ? progress : (1.0 - progress)).clamp(0.0, 1.0);
            }

            // Debug prints removed for production
            return CustomPaint(
              painter: _ProfileCardPainter(
                offColor: widget.offColor,
                onColor: widget.onColor,
                leftRadius: leftRadius,
                rightRadius: rightRadius,
                littleLeftRadius: littleLeftRadius,
                littleRightRadius: littleRightRadius,
                isDragging: _isDragging,
                dragProgress: _smoothedDragProgress,
                debugPointerX: widget.debugShowPointers ? _lastPointerX : null,
                debugSmoothedSmallX:
                    widget.debugShowPointers ? _smoothedSmallX : null,
                drawBackground: widget.animateBackground,
                backgroundMix: backgroundMix,
                backgroundOpacity: widget.backgroundOpacity,
                borderWidth: widget.borderWidth,
                borderColor: widget.borderColor,
                littleBorderWidth: widget.littleBorderWidth,
                littleBorderColor: widget.littleBorderColor,
                littleShadowBlurSigma: widget.littleShadowBlurSigma,
                littleShadowOffset: widget.littleShadowOffset,
                littleShadowColor: widget.littleShadowColor,
                value: displayValue,
                stateValue: value,
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
  late double leftRadius;

  /// Right circle radius.
  late double rightRadius;

  /// Little right circle radius.
  late double littleRightRadius;

  /// Little left circle radius.
  late double littleLeftRadius;

  /// Live drag visualization
  late bool isDragging;

  /// Normalized drag progress in range [-1, 1]
  late double dragProgress;

  /// State of widget.
  /// Visual 'value' used for display (may be affected by drag phases)
  late bool value;

  /// Internal toggle state (true == ON) from the widget's state
  late bool stateValue;

  /// Color when widget is on
  late Color onColor;

  /// Color when widget is off
  late Color offColor;

  /// Whether to draw the animated background tint
  late bool drawBackground;

  /// Background lerp t in [0..1] between offColor->onColor
  late double backgroundMix;

  /// Background opacity [0..1]
  late double backgroundOpacity;

  /// Outer border
  late double borderWidth;
  late Color? borderColor;

  /// Little circle border and shadow
  late double littleBorderWidth;
  late Color? littleBorderColor;
  late double littleShadowBlurSigma;
  late Offset littleShadowOffset;
  late Color littleShadowColor;

  /// Optional debug pointer X to draw
  late double? debugPointerX;

  /// Optional debug smoothed small X to draw
  late double? debugSmoothedSmallX;

  _ProfileCardPainter({
    required this.leftRadius,
    required this.rightRadius,
    required this.littleLeftRadius,
    required this.littleRightRadius,
    required this.isDragging,
    required this.dragProgress,
    required this.value,
    required this.stateValue,
    required this.onColor,
    required this.offColor,
    required this.drawBackground,
    required this.backgroundMix,
    required this.backgroundOpacity,
    required this.borderWidth,
    required this.borderColor,
    required this.littleBorderWidth,
    required this.littleBorderColor,
    required this.littleShadowBlurSigma,
    required this.littleShadowOffset,
    required this.littleShadowColor,
    this.debugPointerX,
    this.debugSmoothedSmallX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Centers for left and right halves
    final double halfW = size.width * 0.5;
    final double quarterW = halfW * 0.5;
    final double midY = size.height * 0.5;
    final Offset leftCenter = Offset(quarterW, midY);
    final Offset rightCenter = Offset(quarterW + halfW, midY);

    // Interpolated center for live drag of little circle
    Offset lerp(Offset a, Offset b, double t) => Offset(
          a.dx + (b.dx - a.dx) * t,
          a.dy + (b.dy - a.dy) * t,
        );

    // Background tint behind circles
    if (drawBackground) {
      final Color lerped =
          Color.lerp(offColor, onColor, backgroundMix) ?? offColor;
      final int alpha = (255 * backgroundOpacity.clamp(0.0, 1.0)).round();
      final Color bg = lerped.withAlpha(alpha);
      final Paint bgPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = bg;
      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.height * 0.5),
      );
      canvas.drawRRect(rrect, bgPaint);
      // Outer border
      if (borderWidth > 0) {
        // Derive borderColor when null: darker version of background tint
        final Color derivedBorder =
            (borderColor ?? _darkerColor(bg, amount: 0.25));
        final Paint borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..color = derivedBorder;
        canvas.drawRRect(rrect, borderPaint);
      }
    }

    final Paint paint = Paint()..strokeWidth = 18;

    if (value) {
      // ON state: draw both circles on RIGHT side
      // Big circle (onColor)
      paint.color = onColor.withValues(alpha: 0.2);
      canvas.drawCircle(rightCenter, rightRadius, paint);

      // Little circle (offColor) animates via littleRightRadius
      if (isDragging) {
        // Move little circle along drag between centers
        // Start from current side to avoid initial jump
        final progressRight = dragProgress > 0 ? dragProgress : 0.0;
        final progressLeft = dragProgress < 0 ? -dragProgress : 0.0;
        final t = stateValue ? (1.0 - progressLeft) : progressRight;
        final dragCenter = lerp(leftCenter, rightCenter, t.clamp(0.0, 1.0));
        final double r =
            littleRightRadius > 0.0 ? littleRightRadius : size.height * 0.14;
        // Shadow for little circle
        if (littleShadowBlurSigma > 0) {
          final Paint shadowPaint = Paint()
            ..color = littleShadowColor
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, littleShadowBlurSigma);
          canvas.drawCircle(
            dragCenter + littleShadowOffset,
            r,
            shadowPaint,
          );
        }
        // Determine current fill color via hue lerp between ON and OFF by backgroundMix,
        // ensuring endpoints align with discrete state colors
        final Color currentFill = _hueLerp(offColor, onColor, backgroundMix);
        // Border (stroke) for little circle (derived darker when not provided)
        if (littleBorderWidth > 0) {
          final Paint strokePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = littleBorderWidth
            ..color = (littleBorderColor ?? _darkerColor(currentFill));
          canvas.drawCircle(dragCenter, r, strokePaint);
        }
        // Fill for little circle — smoothly hue-lerped between ON and OFF
        paint.color = currentFill;
        canvas.drawCircle(dragCenter, r, paint);
      } else if (littleRightRadius > 0.0) {
        final double r = littleRightRadius;
        if (littleShadowBlurSigma > 0) {
          final Paint shadowPaint = Paint()
            ..color = littleShadowColor
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, littleShadowBlurSigma);
          canvas.drawCircle(rightCenter + littleShadowOffset, r, shadowPaint);
        }
        final Color currentFill = _hueLerp(offColor, onColor, backgroundMix);
        if (littleBorderWidth > 0) {
          final Paint strokePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = littleBorderWidth
            ..color = (littleBorderColor ?? _darkerColor(currentFill));
          canvas.drawCircle(rightCenter, r, strokePaint);
        }
        paint.color = currentFill;
        canvas.drawCircle(rightCenter, r, paint);
      }
    } else {
      // OFF state: draw both circles on LEFT side
      // Big circle (offColor)
      paint.color = offColor.withValues(alpha: 0.2);
      canvas.drawCircle(leftCenter, leftRadius, paint);

      // Little circle (onColor) animates via littleLeftRadius
      if (isDragging) {
        // Move little circle along drag between centers
        final progressRight = dragProgress > 0 ? dragProgress : 0.0;
        final progressLeft = dragProgress < 0 ? -dragProgress : 0.0;
        // For OFF (left) initial position at t=0.0: move right using progressRight
        // For ON (right) initial position t=1.0: move left using progressLeft
        final t = stateValue ? (1.0 - progressLeft) : progressRight;
        final dragCenter = lerp(leftCenter, rightCenter, t.clamp(0.0, 1.0));
        final double r =
            littleLeftRadius > 0.0 ? littleLeftRadius : size.height * 0.14;
        if (littleShadowBlurSigma > 0) {
          final Paint shadowPaint = Paint()
            ..color = littleShadowColor
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, littleShadowBlurSigma);
          canvas.drawCircle(dragCenter + littleShadowOffset, r, shadowPaint);
        }
        final Color currentFill = _hueLerp(offColor, onColor, backgroundMix);
        if (littleBorderWidth > 0) {
          final Paint strokePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = littleBorderWidth
            ..color = (littleBorderColor ?? _darkerColor(currentFill));
          canvas.drawCircle(dragCenter, r, strokePaint);
        }
        paint.color = currentFill;
        canvas.drawCircle(dragCenter, r, paint);
      } else if (littleLeftRadius > 0.0) {
        final double r = littleLeftRadius;
        if (littleShadowBlurSigma > 0) {
          final Paint shadowPaint = Paint()
            ..color = littleShadowColor
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, littleShadowBlurSigma);
          canvas.drawCircle(leftCenter + littleShadowOffset, r, shadowPaint);
        }
        final Color currentFill = _hueLerp(offColor, onColor, backgroundMix);
        if (littleBorderWidth > 0) {
          final Paint strokePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = littleBorderWidth
            ..color = (littleBorderColor ?? _darkerColor(currentFill));
          canvas.drawCircle(leftCenter, r, strokePaint);
        }
        paint.color = currentFill;
        canvas.drawCircle(leftCenter, r, paint);
      }
    }
    // Debug overlay: draw pointer and smoothed small circle positions when provided.
    if (kDebugMode && debugPointerX != null) {
      final overlayPaint = Paint()..style = PaintingStyle.fill;
      overlayPaint.color = const Color.fromRGBO(255, 0, 0, 0.9);
      final pointerCenter = Offset(
        debugPointerX!.clamp(leftCenter.dx, rightCenter.dx),
        leftCenter.dy,
      );
      canvas.drawCircle(pointerCenter, size.height * 0.06, overlayPaint);
      if (debugSmoothedSmallX != null) {
        overlayPaint.color = const Color.fromRGBO(0, 255, 0, 0.9);
        final smallCenter = Offset(
          debugSmoothedSmallX!.clamp(leftCenter.dx, rightCenter.dx),
          leftCenter.dy,
        );
        canvas.drawCircle(smallCenter, size.height * 0.05, overlayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ProfileCardPainter oldDelegate) {
    return oldDelegate.leftRadius != leftRadius ||
        oldDelegate.rightRadius != rightRadius ||
        oldDelegate.littleLeftRadius != littleLeftRadius ||
        oldDelegate.littleRightRadius != littleRightRadius ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.dragProgress != dragProgress ||
        oldDelegate.value != value ||
        oldDelegate.stateValue != stateValue ||
        oldDelegate.onColor != onColor ||
        oldDelegate.offColor != offColor ||
        oldDelegate.drawBackground != drawBackground ||
        oldDelegate.backgroundMix != backgroundMix ||
        oldDelegate.backgroundOpacity != backgroundOpacity ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.littleBorderWidth != littleBorderWidth ||
        oldDelegate.littleBorderColor != littleBorderColor ||
        oldDelegate.littleShadowBlurSigma != littleShadowBlurSigma ||
        oldDelegate.littleShadowOffset != littleShadowOffset ||
        oldDelegate.littleShadowColor != littleShadowColor ||
        oldDelegate.debugPointerX != debugPointerX ||
        oldDelegate.debugSmoothedSmallX != debugSmoothedSmallX;
  }

  // Utility: derive a darker color (reduce lightness)
  Color _darkerColor(Color base, {double amount = 0.2}) {
    final hsl = HSLColor.fromColor(base);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  // Utility: interpolate hue between two colors by t, preserving saturation and lightness
  Color _hueLerp(Color a, Color b, double t) {
    final ha = HSLColor.fromColor(a);
    final hb = HSLColor.fromColor(b);
    // Wrap-safe hue interpolation across 0/360 boundary
    double dh = hb.hue - ha.hue;
    if (dh > 180) dh -= 360;
    if (dh < -180) dh += 360;
    final hue = (ha.hue + dh * t) % 360;
    final sat = ha.saturation + (hb.saturation - ha.saturation) * t;
    final light = ha.lightness + (hb.lightness - ha.lightness) * t;
    final alpha = ha.alpha + (hb.alpha - ha.alpha) * t;
    return HSLColor.fromAHSL(alpha, hue, sat, light).toColor();
  }
  // (removed) Hue interpolation utility no longer needed when small circle uses discrete state colors
}
