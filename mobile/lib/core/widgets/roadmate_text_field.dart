import 'package:flutter/material.dart';

/// Themed text field with 56 dp height, filled background, and 12 px
/// border radius.
///
/// Wraps [TextField] with the app's input decoration theme and
/// ensures the touch target meets the 56 dp minimum.
class RoadmateTextField extends StatelessWidget {
  /// Text editing controller.
  final TextEditingController? controller;

  /// Placeholder text.
  final String? hintText;

  /// Field label shown above the input.
  final String? labelText;

  /// Leading icon inside the field.
  final IconData? prefixIcon;

  /// Trailing widget (e.g. clear button, suffix text).
  final Widget? suffix;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Whether to obscure input (for passwords).
  final bool obscureText;

  /// Called when text changes.
  final ValueChanged<String>? onChanged;

  /// Maximum number of lines (null = single line).
  final int? maxLines;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Called when the field is tapped (useful for date pickers, etc.).
  final VoidCallback? onTap;

  const RoadmateTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 22)
            : null,
        suffixIcon: suffix,
      ),
    );
  }
}
