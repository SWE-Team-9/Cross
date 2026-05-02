// Minimal stub for Subscription used across the app.
class Subscription {
  final String subscriptionType;
  final int uploadLimit;
  final int uploadedTracks;
  final int remainingUploads;
  final bool cancelAtPeriodEnd;
  final bool canDownload;
  final bool adsEnabled;

  const Subscription({
    this.subscriptionType = 'FREE',
    this.uploadLimit = 3,
    this.uploadedTracks = 0,
    this.remainingUploads = 3,
    this.cancelAtPeriodEnd = false,
    this.canDownload = false,
    this.adsEnabled = true,
  });

  bool get isPro => subscriptionType != 'FREE';
}
