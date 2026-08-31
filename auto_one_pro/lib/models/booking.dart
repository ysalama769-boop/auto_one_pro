class Booking {
  final String id;
  final String carId;
  final String carTitle;
  final String customerName;
  final String nationalId;
  final String phone;
  final String city;
  final DateTime createdAt;
  final String status;

  const Booking({
    required this.id,
    required this.carId,
    required this.carTitle,
    required this.customerName,
    required this.nationalId,
    required this.phone,
    required this.city,
    required this.createdAt,
    required this.status,
  });
}
