/// Fixed spacing/radius scale — every screen pulls padding, gaps and corner
/// radii from here instead of hand-picking pixel values, so layouts keep the
/// same breathing room the reference mockup has.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusPill = 999.0;

  static const minTapTarget = 48.0;
}
