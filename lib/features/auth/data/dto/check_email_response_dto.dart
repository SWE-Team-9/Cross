class CheckEmailResponseDto {
  final bool exists;

  const CheckEmailResponseDto({
    required this.exists,
  });

  factory CheckEmailResponseDto.fromJson(Map<String, dynamic> json) {
    return CheckEmailResponseDto(
      exists: json['exists'] ?? false,
    );
  }
}