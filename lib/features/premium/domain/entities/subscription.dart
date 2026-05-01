class Subscription {
  final String subscriptionType;
  final int uploadLimit;
  final int uploadedTracks;
  final int remainingUploads;
  final bool cancelAtPeriodEnd;
  final bool canDownload;
  final bool adsEnabled;

  const Subscription({
    required this.subscriptionType,
    required this.uploadLimit,
    required this.uploadedTracks,
    required this.remainingUploads,
    this.cancelAtPeriodEnd = false,
    this.canDownload = false,
    this.adsEnabled = true,
  });

  bool get isPro => subscriptionType != 'FREE';
}
