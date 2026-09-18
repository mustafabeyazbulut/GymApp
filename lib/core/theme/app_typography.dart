import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Yerel olarak paketlenmiş Inter fontu üzerine kurulu ağırlık/opaklık
/// hiyerarşisi — başlıklar bold/semibold, gövde metni regular, yardımcı
/// metin daha düşük opaklıkta gri. Material'ın varsayılan Roboto fontuna
/// asla geri düşmez.
abstract final class AppTypography {
  static const _fontFamily = 'Inter';

  static const TextTheme textTheme = TextTheme(
    headlineSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.onBackground,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.onBackground,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.onBackground,
      height: 1.3,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.onBackground,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.onBackgroundMuted,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.onPrimary,
      height: 1.2,
    ),
    labelSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.onBackgroundFaint,
      height: 1.2,
      letterSpacing: 0.2,
    ),
  );
}
