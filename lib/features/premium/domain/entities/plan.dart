// Minimal stub for Plan used by premium feature callers.
class Plan {
  final String code;
  final String name;
  final double price;
  final String description;
  final String interval;

  const Plan({
    this.code = '',
    this.name = '',
    this.price = 0.0,
    this.description = '',
    this.interval = 'month',
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      interval: json['interval'] ?? 'month',
    );
  }
}
