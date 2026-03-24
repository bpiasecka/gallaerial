import 'package:flutter/material.dart';

extension ColorToHex on Color {
  /// Converts a Flutter Color to a hex string.
  /// 
  /// [leadingHashSign] adds a '#' to the beginning (default: true).
  /// [withAlpha] includes the 2-digit alpha channel (default: true).
  String toHex({bool leadingHashSign = true, bool withAlpha = true}) {
    
    // 1. Get the 32-bit integer representation of the color.
    // NOTE: If you are on an older version of Flutter (< 3.27), replace `toARGB32()` with `.value`.
    final int argb = toARGB32(); 
    
    // 2. Convert to hex, pad with leading zeros to ensure 8 characters, and uppercase
    String hex = argb.toRadixString(16).padLeft(8, '0').toUpperCase();
    
    // 3. Remove the first two characters (alpha channel) if requested
    if (!withAlpha) {
      hex = hex.substring(2);
    }
    
    // 4. Return the formatted string
    return '${leadingHashSign ? '#' : ''}$hex';
  }
}

extension HexStringToColor on String {
  /// Converts a hex color string to a Flutter Color object.
  Color toColor() {
    // 1. Remove the leading '#' if it exists
    String hex = replaceAll('#', '').toUpperCase();

    // 2. Validate the length (must be 6 or 8 characters)
    if (hex.length != 6 && hex.length != 8) {
      // Return a default color (like transparent) or throw an error if the string is invalid
      debugPrint('Warning: Invalid hex string $this. Defaulting to transparent.');
      return Colors.transparent;
    }

    // 3. If the string is 6 characters long (no alpha channel), add 'FF' for full opacity
    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    // 4. Parse the string as a hexadecimal integer and convert it to a Color
    return Color(int.parse(hex, radix: 16));
  }
}