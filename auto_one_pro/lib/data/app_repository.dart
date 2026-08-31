import '../models/booking.dart';
import '../models/car.dart';

class AppRepository {
  AppRepository._();
  static final AppRepository instance = AppRepository._();

  final List<Car> cars = [
    const Car(
      id: 'AO-0001', brand: 'KIA', model: 'Sportage', year: '2025', trim: 'Smart',
      price: '125,000 ر.س', category: CarCategory.suv, status: CarStatus.available,
      description: 'سيارة SUV عملية بتصميم حديث وتجهيزات مناسبة للاستخدام اليومي والعائلي.',
      images: [
        'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?q=85&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?q=85&w=1200&auto=format&fit=crop',
      ],
    ),
    const Car(
      id: 'AO-0002', brand: 'Toyota', model: 'Land Cruiser', year: '2025', trim: 'GXR',
      price: '320,000 ر.س', category: CarCategory.luxury, status: CarStatus.available,
      description: 'دفع رباعي فاخر بمساحة كبيرة وحضور قوي على الطريق.',
      images: [
        'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?q=85&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?q=85&w=1200&auto=format&fit=crop',
      ],
    ),
    const Car(
      id: 'AO-0003', brand: 'Jetour', model: 'X70 Plus', year: '2025', trim: 'Luxury',
      price: '99,000 ر.س', category: CarCategory.family, status: CarStatus.reserved,
      description: 'SUV عائلية واسعة مع تجهيزات راحة وتقنيات حديثة.',
      images: [
        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=85&w=1200&auto=format&fit=crop',
      ],
    ),
  ];

  final List<Booking> bookings = [];

  List<Car> search({String query = '', CarCategory? category, CarStatus? status}) {
    final q = query.trim().toLowerCase();
    return cars.where((car) {
      final text = '${car.brand} ${car.model} ${car.year} ${car.trim}'.toLowerCase();
      return (q.isEmpty || text.contains(q)) &&
          (category == null || car.category == category) &&
          (status == null || car.status == status);
    }).toList();
  }

  void addBooking(Booking booking) => bookings.add(booking);

  int count(CarStatus status) => cars.where((c) => c.status == status).length;
}
