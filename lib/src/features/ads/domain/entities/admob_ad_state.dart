enum AdLoadStatus { initial, loading, loaded, failed, opened, dismissed }

/// Represents the reactive state of an AdMob ad format (Banner or Interstitial).
class AdmobAdState {
  final AdLoadStatus status;
  final String? adUnitId;
  final String? errorMessage;
  final int impressionsCount;
  final int clicksCount;

  const AdmobAdState({
    this.status = AdLoadStatus.initial,
    this.adUnitId,
    this.errorMessage,
    this.impressionsCount = 0,
    this.clicksCount = 0,
  });

  bool get isLoading => status == AdLoadStatus.loading;
  bool get isLoaded => status == AdLoadStatus.loaded;
  bool get isFailed => status == AdLoadStatus.failed;
  bool get isOpened => status == AdLoadStatus.opened;
  bool get isDismissed => status == AdLoadStatus.dismissed;

  AdmobAdState copyWith({
    AdLoadStatus? status,
    String? adUnitId,
    String? errorMessage,
    int? impressionsCount,
    int? clicksCount,
  }) {
    return AdmobAdState(
      status: status ?? this.status,
      adUnitId: adUnitId ?? this.adUnitId,
      errorMessage: errorMessage ?? this.errorMessage,
      impressionsCount: impressionsCount ?? this.impressionsCount,
      clicksCount: clicksCount ?? this.clicksCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdmobAdState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          adUnitId == other.adUnitId &&
          errorMessage == other.errorMessage &&
          impressionsCount == other.impressionsCount &&
          clicksCount == other.clicksCount;

  @override
  int get hashCode => Object.hash(
    status,
    adUnitId,
    errorMessage,
    impressionsCount,
    clicksCount,
  );
}
