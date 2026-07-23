import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneclick_cars/utils/button_utils.dart';

void main() {
  test('returns white text on dark backgrounds', () {
    expect(getContrastTextColor(const Color(0xFF0F172A)), Colors.white);
  });

  test('returns black text on light backgrounds', () {
    expect(getContrastTextColor(Colors.white), Colors.black);
  });
}
