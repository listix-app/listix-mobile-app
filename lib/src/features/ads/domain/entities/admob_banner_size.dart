/// Standard Google AdMob banner ad dimensions.
enum AdmobBannerSize {
  /// Standard phone banner: 320 x 50
  standard(width: 320, height: 50, label: '320x50 Banner'),

  /// Large banner: 320 x 100
  large(width: 320, height: 100, label: '320x100 Large Banner'),

  /// Medium rectangle (IAB): 300 x 250
  mediumRectangle(width: 300, height: 250, label: '300x250 Medium Rectangle'),

  /// Adaptive banner that spans full available width with a 50-60dp height
  adaptive(width: double.infinity, height: 56, label: 'Adaptive Banner');

  final double width;
  final double height;
  final String label;

  const AdmobBannerSize({
    required this.width,
    required this.height,
    required this.label,
  });
}
