class CheckUploadLimitUseCase {
  bool call({
    required int remainingUploads,
    required bool isPro,
  }) {
    if (isPro) return true;
    return remainingUploads > 0;
  }
}
