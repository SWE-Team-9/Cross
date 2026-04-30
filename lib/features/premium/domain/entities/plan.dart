class Plan {
  final String code;
  final String name;
  final String description;
  final double price;
  final String interval; // monthly / yearly

  const Plan({
    required this.code,
    required this.name,
    required this.description,
    required this.price,
    required this.interval,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      interval: json['interval'] ?? 'monthly',
    );
  }
}
