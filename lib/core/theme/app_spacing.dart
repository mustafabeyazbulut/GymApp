/// Sabit boşluk/köşe yarıçapı ölçeği — her ekran, piksel değerlerini elle
/// seçmek yerine padding, boşluk ve köşe yarıçaplarını buradan alır; böylece
/// tasarımlar referans mockup'taki aynı nefes alma boşluğunu korur.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 22.0;
  static const radiusPill = 999.0;

  static const minTapTarget = 48.0;
}
