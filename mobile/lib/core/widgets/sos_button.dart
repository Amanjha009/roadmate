import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Large circular SOS button with slide-to-activate functionality.
///
/// The button is 80 dp in diameter. The user must slide the inner
/// handle to the right to confirm SOS activation, preventing
/// accidental triggers.
class SOSButton extends StatefulWidget {
  /// Called when the user completes the slide-to-activate gesture.
  final VoidCallback onActivated;

  /// Diameter of the outer circle.
  final double size;

  const SOSButton({
    super.key,
    required this.onActivated,
    this.size = 80,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  late final double _maxDrag;
  late final AnimationController _resetController;

  @override
  void initState() {
    super.initState();
    _maxDrag = widget.size * 2;
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {
          _dragExtent = _dragExtent * (1 - _resetController.value);
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent = (_dragExtent + details.primaryDelta!)
          .clamp(0.0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragExtent >= _maxDrag * 0.85) {
      widget.onActivated();
    }
    _resetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragExtent / _maxDrag).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slide track.
        Container(
          width: _maxDrag + widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size / 2),
            color: AppColors.statusRed.withOpacity(0.15),
            border: Border.all(
              color: AppColors.statusRed.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Label.
              Center(
                child: Padding(
                  padding: EdgeInsets.only(left: widget.size),
                  child: Text(
                    'SLIDE TO SOS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusRed.withOpacity(1 - progress),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              // Draggable handle.
              Positioned(
                left: _dragExtent,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    // NON-NEGOTIABLE SAFETY LINE: 100% solid #FF5C00 fill, zero blur
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x99FF5C00),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
