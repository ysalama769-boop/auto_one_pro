enum CarStatus { available, reserved, sold }

enum CarCategory { suv, sedan, sport, luxury, family }

class Car {
  final String id;
  final String brand;
  final String model;
  final String year;
  final String trim;
  final String price;
  final CarCategory category;
  final CarStatus status;
  final String description;
  final List<String> images;

  const Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.trim,
    required this.price,
    required this.category,
    required this.status,
    required this.description,
    required this.images,
  });

  String get title => '$brand $model';
  String get fullTitle => '$brand $model $year';
}
