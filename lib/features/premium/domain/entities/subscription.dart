class Subscription {
  final String subscriptionType;
  final int uploadLimit;
  final int uploadedTracks;
  final int remainingUploads;

  const Subscription({
    required this.subscriptionType,
    required this.uploadLimit,
    required this.uploadedTracks,
    required this.remainingUploads,
  });

  bool get isPro => subscriptionType != 'FREE';
}
