import 'package:flutter/material.dart';

/// Placeholder palette approximated from the user's "MAT & MOVE" reference
/// mockup. Colors, not craft level, are the placeholder part — see
/// `docs/superpowers/specs/2026-09-14-mobile-foundation-design.md`.
/// Swapping the real brand palette later is a change to this file only.
abstract final class AppColors {
  static const background = Color(0xFF0D0D0F);
  static const surface = Color(0xFF1A1A1D);
  static const surfaceElevated = Color(0xFF232327);

  static const primary = Color(0xFF8BC34A);
  static const onPrimary = Color(0xFF0D0D0F);
  static const secondary = Color(0xFF2DD4BF);

  static const onBackground = Color(0xFFF5F5F5);
  static const onBackgroundMuted = Color(0xFFA1A1AA);
  static const onBackgroundFaint = Color(0xFF8E8E96);

  static const border = Color(0xFF2A2A2E);
  static const error = Color(0xFFFF6B6B);
  static const errorSurface = Color(0x1AFF6B6B);
  static const successSurface = Color(0x1A8BC34A);
}
