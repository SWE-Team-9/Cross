class Subscription {
  final String subscriptionType;
  final int uploadLimit;
  final int uploadedTracks;
  final int remainingUploads;
  final bool cancelAtPeriodEnd;

  const Subscription({
    required this.subscriptionType,
    required this.uploadLimit,
    required this.uploadedTracks,
    required this.remainingUploads,
    this.cancelAtPeriodEnd = false,
  });

  bool get isPro => subscriptionType != 'FREE';
}
