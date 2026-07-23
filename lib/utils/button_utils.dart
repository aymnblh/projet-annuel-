import 'package:flutter/material.dart';

Color getContrastTextColor(Color backgroundColor) {
  final luminance = backgroundColor.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}
