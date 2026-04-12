abstract class UploadPickerException implements Exception {
  const UploadPickerException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

class UploadPickerPermissionPermanentlyDeniedException
    extends UploadPickerException {
  const UploadPickerPermissionPermanentlyDeniedException(super.message);
}
