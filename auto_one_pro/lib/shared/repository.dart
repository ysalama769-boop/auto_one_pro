import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';

// ============================================================
// CAR COLORS CACHE (loaded from Supabase per car)
// ============================================================
// بتخزن الألوان المتاحة لكل سيارة حسب الـ id بتاعها
Map<int, List<CarColor>> carColorsCache = {};


// بتجيب الألوان المتاحة لسيارة واحدة من car_color_availability + colors
Future<List<CarColor>> fetchColorsForCar(int carId) async {
  try {
    final response = await Supabase.instance.client
        .from('car_color_availability')
        .select('color_id, is_available, colors(id, name_ar, name_en, color_value)')
        .eq('car_id', carId)
        .eq('is_available', true);

    return (response as List)
        .where((row) => row['colors'] != null)
        .map((row) => CarColor.fromMap(row['colors'] as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل ألوان السيارة $carId: $e');
    return [];
  }
}


// بتجيب ألوان كل السيارات دفعة واحدة (طلب واحد بس، مش طلب لكل سيارة)
Future<void> loadColorsForCars(List<Car> carsList) async {
  try {
    final response = await Supabase.instance.client
        .from('car_color_availability')
        .select('car_id, color_id, is_available, image, colors(id, name_ar, name_en, color_value)')
        .eq('is_available', true);

    final Map<int, List<CarColor>> grouped = {};

    for (final row in (response as List)) {
      final map = row as Map<String, dynamic>;
      final carId = map['car_id'] as int?;
      final colorData = map['colors'];
      if (carId == null || colorData == null) continue;

      final baseColor = CarColor.fromMap(colorData as Map<String, dynamic>);
      final colorImage = map['image'] as String?;
      final color = CarColor(
        id: baseColor.id,
        nameAr: baseColor.nameAr,
        nameEn: baseColor.nameEn,
        colorValue: baseColor.colorValue,
        image: (colorImage != null && colorImage.trim().isNotEmpty)
            ? colorImage.trim()
            : null,
      );
      grouped.putIfAbsent(carId, () => []).add(color);
    }

    carColorsCache = grouped;
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل الألوان: $e');
  }
}


// ============================================================
// CAR IMAGES CACHE (loaded from Supabase, bulk query)
// ============================================================
// بتخزن كل صور معرض كل سيارة حسب الـ id بتاعها
Map<int, List<String>> carImagesCache = {};


// بتجيب صور كل السيارات دفعة واحدة (طلب واحد بس)
Future<void> loadImagesForCars(List<Car> carsList) async {
  try {
    final response = await Supabase.instance.client
        .from('car_images')
        .select('car_id, image');

    final Map<int, List<String>> grouped = {};

    for (final row in (response as List)) {
      final map = row as Map<String, dynamic>;
      final carId = map['car_id'] as int?;
      final image = map['image'] as String?;
      if (carId == null || image == null || image.isEmpty) continue;

      grouped.putIfAbsent(carId, () => []).add(image);
    }

    carImagesCache = grouped;
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل صور المعرض: $e');
  }
}

const List<CarColor> carColorLibrary = [
  CarColor(
    id: 'white',
    nameAr: 'أبيض',
    nameEn: 'White',
    colorValue: 0xFFFFFFFF,
  ),

  CarColor(
    id: 'pearl_white',
    nameAr: 'أبيض لؤلؤي',
    nameEn: 'Pearl White',
    colorValue: 0xFFF5F5F0,
  ),

  CarColor(
    id: 'black',
    nameAr: 'أسود',
    nameEn: 'Black',
    colorValue: 0xFF000000,
  ),

  CarColor(
    id: 'silver',
    nameAr: 'فضي',
    nameEn: 'Silver',
    colorValue: 0xFFC0C0C0,
  ),

  CarColor(
    id: 'gray',
    nameAr: 'رمادي',
    nameEn: 'Gray',
    colorValue: 0xFF808080,
  ),

  CarColor(
    id: 'blue',
    nameAr: 'أزرق',
    nameEn: 'Blue',
    colorValue: 0xFF2196F3,
  ),

  CarColor(
    id: 'navy',
    nameAr: 'كحلي',
    nameEn: 'Navy Blue',
    colorValue: 0xFF0B1F3A,
  ),

  CarColor(
    id: 'red',
    nameAr: 'أحمر',
    nameEn: 'Red',
    colorValue: 0xFFF44336,
  ),

  CarColor(
    id: 'burgundy',
    nameAr: 'نبيتي',
    nameEn: 'Burgundy',
    colorValue: 0xFF800020,
  ),

  CarColor(
    id: 'brown',
    nameAr: 'بني',
    nameEn: 'Brown',
    colorValue: 0xFF795548,
  ),

  CarColor(
    id: 'beige',
    nameAr: 'بيج',
    nameEn: 'Beige',
    colorValue: 0xFFD8C3A5,
  ),

  CarColor(
    id: 'gold',
    nameAr: 'ذهبي',
    nameEn: 'Gold',
    colorValue: 0xFFD4AF37,
  ),

  CarColor(
    id: 'green',
    nameAr: 'أخضر',
    nameEn: 'Green',
    colorValue: 0xFF4CAF50,
  ),

  CarColor(
    id: 'orange',
    nameAr: 'برتقالي',
    nameEn: 'Orange',
    colorValue: 0xFFFF9800,
  ),

  CarColor(
    id: 'yellow',
    nameAr: 'أصفر',
    nameEn: 'Yellow',
    colorValue: 0xFFFFEB3B,
  ),

  CarColor(
    id: 'bronze',
    nameAr: 'برونزي',
    nameEn: 'Bronze',
    colorValue: 0xFFCD7F32,
  ),
];


// ============================================================
// LOAD CARS FROM SUPABASE
// ============================================================
// بتجيب السيارات المتاحة من الجدول وتحدّث القايمة العامة cars
// لو حصل أي خطأ (زي مفيش إنترنت)، القايمة الثابتة تحت بتفضل شغالة كـ احتياطي
Future<void> loadCarsFromSupabase() async {
  try {
    // بنجيب بس الأعمدة اللي محتاجينها لعرض كروت السيارات في الصفحة
    // الرئيسية وقائمة السيارات (مش كل تفاصيل السيارة زي الأبعاد
    // والمواصفات الكاملة)، وده بيقلل حجم البيانات اللي بتتحمّل بشكل
    // كبير خصوصًا مع عدد كبير من السيارات. التفاصيل الكاملة بتتحمّل
    // بعدين لما حد يفتح صفحة سيارة معيّنة (CarDetailsPage).
    final response = await Supabase.instance.client
        .from('cars')
        .select(
          'id, brand, name, name_en, category, year, price, image, '
          'description, description_en, engine, fuel, seats, transmission, '
          'drive, horsepower, airbags, '
          'is_offer, old_price, discount_percent, offer_start_date, '
          'offer_end_date, is_featured, is_available, sort_order, '
          'view_count, car_status, condition_status',
        )
        .eq('is_available', true)
        .order('sort_order', nullsFirst: false);

    debugPrint('AUTO_ONE_DEBUG: raw response = $response');

    final fetched = (response as List)
        .map((row) => Car.fromMap(row as Map<String, dynamic>))
        .toList();

    debugPrint('AUTO_ONE_DEBUG: fetched ${fetched.length} cars from Supabase');

    if (fetched.isNotEmpty) {
      cars = fetched;
      debugPrint('AUTO_ONE_DEBUG: cars list replaced successfully');
      await Future.wait([
        loadColorsForCars(fetched),
        loadImagesForCars(fetched),
      ]);
      debugPrint('AUTO_ONE_DEBUG: colors loaded for ${carColorsCache.length} cars, images loaded for ${carImagesCache.length} cars');
    } else {
      debugPrint('AUTO_ONE_DEBUG: fetched list was empty, keeping fallback data');
    }
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: EXCEPTION while loading cars: $e');
  }
}


// ============================================================
// REAL INVENTORY (fallback / initial data)
// ============================================================

List<Car> cars = [
  // ============================================================
  // TOYOTA - 2
  // ============================================================

  Car(
  id: 1,
  name: 'يارس واي بلس',
  brand: 'Toyota',
  category: 'TOYOTA',
  year: '2026',
  price: '66,550 ﷼',
  image: 'assets/youssefcar4.jpg',
  colorImages: {
  'white': 'assets/yaris_white.jpeg',
  'black': 'assets/yaris_black.jpeg',
  'gray': 'assets/yaris_gray.jpeg',
},
  description: 'Toyota Yaris من مخزون AUTO ONE.',
  seats: '7',

  availableColorIds: [
  'white',
  'black',
  'gray',
  ],
),

  Car(
    id: 2,
    name: 'تويوتا كورولا 2.0 استاندر',
    brand: 'Toyota',
    category: 'TOYOTA',
    year: '2026',
    price: '80,000 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Toyota Corolla 2.0.',
  ),

  // ============================================================
  // HYUNDAI - 18
  // ============================================================

  Car(
    id: 3,
    name: 'اكسنت 1.5 فليت جنوط',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '65285 ريال ',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Accent 1.5.',
  ),

  Car(
    id: 4,
    name: 'اكسنت 1.5 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '69425 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Accent 1.5 Smart.',
  ),

  Car(
    id: 5,
    name: 'النترا 1.5 سمارت  ',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '77,475 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Elantra 1.5 Smart.',
  ),

  Car(
    id: 6,
    name: 'النترا سمارت 2000 سي سي  ',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '82,650 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Elantra 2.0 Smart.',
  ),

  Car(
    id: 7,
    name: 'النترا 2.0 سمارت بلس ',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '82,650 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Elantra 2.0 Smart Plus.',
  ),

  Car(
    id: 8,
    name: 'النترا 2.0 كمفورت ',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '90,700 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Elantra 2.0 Comfort.',
  ),

  Car(
    id: 9,
    name: 'كونا 2.0 كمفورت توتون',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2025',
    price: '87,250 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Kona 2.0 Comfort.',
  ),

  Car(
    id: 10,
    name: 'كونا 2.0 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '84,375 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Kona 2.0 Smart.',
  ),

  Car(
    id: 11,
    name: 'كونا 2.0 كمفورت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '93,575 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Kona 2.0 Comfort.',
  ),

  Car(
    id: 12,
    name: 'كريتا 1.5 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '76,325 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta 1.5 Smart.',
  ),

  Car(
    id: 13,
    name: 'كريتا 1.5 كمفورت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '84,950',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta 1.5 Comfort.',
  ),

  Car(
    id: 14,
    name: 'كريتا 2.0 جراند سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2025',
    price: '85,525 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta Grand Smart 2.0.',
  ),

  Car(
    id: 15,
    name: 'كريتا جراند سمارت 2000 سي سي',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta Grand Smart 2.0.',
  ),

  Car(
    id: 16,
    name: 'كريتا جراند كمفورت 2000 سي سي',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Creta Grand Comfort 2.0.',
  ),

  Car(
    id: 17,
    name: 'توسان 1.6 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Tucson 1.6 Smart.',
  ),

  Car(
    id: 18,
    name: 'توسان 1.6 سمارت لون تون',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Tucson 1.6 Smart.',
  ),

  Car(
    id: 19,
    name: 'سوناتا 2.5 سمارت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Sonata 2.5 Smart.',
  ),

  Car(
    id: 20,
    name: 'سوناتا 2.5 كمفورت',
    brand: 'Hyundai',
    category: 'HYUNDAI',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Hyundai Sonata 2.5 Comfort.',
  ),

  // ============================================================
  // KIA - 24
  // ============================================================

  Car(
    id: 21,
    name: 'بيجاس 1.4 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Pegas 1.4.',
  ),

  Car(
    id: 22,
    name: 'K3 1.6 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K3 1.6.',
  ),

  Car(
    id: 23,
    name: 'K4 1.6 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K4 1.6 GL.',
  ),

  Car(
    id: 24,
    name: 'K4 1.6 استاندر GL بلس بصمة',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K4 1.6 GL Plus.',
  ),

  Car(
    id: 25,
    name: 'K4 2.0 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K4 2.0.',
  ),

  Car(
    id: 26,
    name: 'K5 2.0 2500 بصمة جي في فتحة سقف',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K5.',
  ),

  Car(
    id: 27,
    name: 'K5 2.0 2500 بصمة GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K5 GL.',
  ),

  Car(
    id: 28,
    name: 'K5 2.0 2500 بصمة نصف فل GLS لون احمر',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K5 GLS.',
  ),

  Car(
    id: 29,
    name: 'K5 2.0 2500 بصمة نصف فل GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K5 GLS.',
  ),

  Car(
    id: 30,
    name: 'K8 1.5 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia K8 1.5.',
  ),

  Car(
    id: 31,
    name: 'Sonet 1.5 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/sonet full4.jpeg',
    description: 'Kia Sonet 1.5.',
  ),

  Car(
    id: 32,
    name: 'Sonet 1.5 GL كامل بدون فتحة',
    brand: 'Kia',
    category: 'KIA',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/sonet full4.jpeg',
    description: 'Kia Sonet 1.5.',
  ),

  Car(
    id: 33,
    name: 'Sonet 1.5 GL كامل بدون فتحة',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/sonet full4.jpeg',
    description: 'Kia Sonet 1.5.',
      specifications: [
    'محرك 2.5 لتر',
    'قير أوتوماتيك',
    'بنزين',
    '5 مقاعد',
    'دفع أمامي',
  ],
  ),

  Car(
    id: 34,
    name: 'Sonet 1.5 GLS فل كامل فتحة سقف',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/sonet full4.jpeg',
    description: 'Kia Sonet GLS.',
  ),

  Car(
    id: 36,
    name: 'سيلتوس 1.5 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Seltos 1.5.',
  ),

  Car(
    id: 37,
    name: 'سيلتوس 1.5 نصف فل GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Seltos GLS.',
  ),

  Car(
    id: 38,
    name: 'كارينز 1.5 استاندر شكل جديد GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Carens 1.5.',
  ),

  Car(
    id: 39,
    name: 'كارينز 1.5 نصف فل شكل جديد GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Carens GLS.',
  ),

  Car(
    id: 40,
    name: 'سورينتو 1.6 هايبرد استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Sorento Hybrid.',
  ),

  Car(
    id:41,
    name: 'سورينتو 1.6 هايبرد نصف فل GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Sorento Hybrid GLS.',
  ),

  Car(
    id: 42,
    name: 'كرنفال 3.5 استاندر GL',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Carnival 3.5.',
  ),

  Car(
    id: 43,
    name: 'كرنفال 3.5 نصف فل GLS',
    brand: 'Kia',
    category: 'KIA',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Carnival GLS.',
  ),

  Car(
    id: 44,
    name: 'تيلورايد 3.8 توب كراسي منفصلة DCM داش كام',
    brand: 'Kia',
    category: 'KIA',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Telluride 3.8.',
  ),

  Car(
    id: 45,
    name: 'تيلورايد 3.8 4x4 GLS-MID',
    brand: 'Kia',
    category: 'KIA',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'Kia Telluride 3.8 4x4.',
  ),

  // ============================================================
  // NISSAN - 11
  // ============================================================

  Car(
    id: 46,
    name: 'نيسان ماجنيت استاندر',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Magnite.',
  ),

  Car(
    id: 47,
    name: 'ماجنيت نصف فل SV',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Magnite SV.',
  ),

  Car(
    id: 48,
    name: 'اكستريل 7 مقاعد استاندر 2.5 دفع ثنائي',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan X-Trail 7 Seats.',
  ),

  Car(
    id: 49,
    name: 'اكستريل 5 مقاعد استاندر 2.5 دفع رباعي',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan X-Trail 5 Seats AWD.',
  ),

  Car(
    id: 50,
    name: 'اكستريل 7 مقاعد استاندر 2.5 دفع ثنائي',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan X-Trail 7 Seats.',
  ),

  Car(
    id: 51,
    name: 'اكستريل 5 مقاعد استاندر 2.5 دفع رباعي',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan X-Trail 5 Seats AWD.',
  ),

  Car(
    id: 52,
    name: 'التيما 2.5L S',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Altima 2.5L S.',
  ),

  Car(
    id: 53,
    name: 'التيما 2.5L SV',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Altima 2.5L SV.',
  ),

  Car(
    id: 54,
    name: 'نصف فل PATROL V6 SE T 2 3.8T 9AT',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Patrol V6.',
  ),

  Car(
    id: 55,
    name: 'نصف فل PATROL V6 SE T 2 3.8T 9AT',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Patrol V6..black ',
  ),

  Car(
    id: 56,
    name: 'باترول بلاتينيوم  تيربو 3.8',
    brand: 'Nissan',
    category: 'NISSAN',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Nissan Patrol Platinum.',
  ),

  // ============================================================
  // FORD - 8
  // ============================================================

  Car(
    id: 57,
    name: 'تيريتوري 1.8 ايمبيتي',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Territory 1.8.',
  ),

  Car(
    id: 58,
    name: 'تيريتوري 1.8 ترند',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Territory Trend.',
  ),

  Car(
    id: 59,
    name: 'تيريتوري 1.8 تيتانيوم',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Territory Titanium.',
  ),

  Car(
    id: 60,
    name: 'تورس 2.0 ترند الشكل الجديد',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Taurus Trend.',
  ),

  Car(
    id: 61,
    name: 'تورس 2.0 تيتانيوم الشكل الجديد',
    brand: 'Ford',
    category: 'FORD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Taurus Titanium.',
  ),

  Car(
    id: 62,
    name: 'فورد اكسبلور XLS بنزين 4x4',
    brand: 'Ford',
    category: 'FORD',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Explorer XLS.',
  ),

  Car(
    id: 63,
    name: 'فورد اكسبلور XLS بنزين 4x4',
    brand: 'Ford',
    category: 'FORD',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Explorer XLS.',
  ),

  Car(
    id: 64,
    name: 'فورد اكسبلور XLT بنزين 4x4',
    brand: 'Ford',
    category: 'FORD',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar1.jpg',
    description: 'Ford Explorer XLT.',
  ),

  // ============================================================
  // BAIC - 6
  // ============================================================

  Car(
    id: 65,
    name: 'بايك U5 لاكشري',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC U5 Luxury.',
  ),

  Car(
    id: 66,
    name: 'بايك U5 لاكشري فتحة سقف',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC U5 Luxury Sunroof.',
  ),

  Car(
    id: 67,
    name: 'بايك X35 ستاندر',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC X35.',
  ),

  Car(
    id: 68,
    name: 'بايك X35 فل لاكشري',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC X35 Luxury.',
  ),

  Car(
    id: 69,
    name: 'بايك X55 كمفورت',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC X55 Comfort.',
  ),

  Car(
    id: 70,
    name: 'بايك X75 كمفورت',
    brand: 'BAIC',
    category: 'BAIC',
    year: '2027',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'BAIC X75 Comfort.',
  ),

  // ============================================================
  // BYD - 2
  // ============================================================

  Car(
    id: 71,
    name: 'Song Plus FWD',
    brand: 'BYD',
    category: 'BYD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'BYD Song Plus FWD.',
  ),

  Car(
    id: 72,
    name: 'Song Plus AWD',
    brand: 'BYD',
    category: 'BYD',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'BYD Song Plus AWD.',
  ),

  // ============================================================
  // JETOUR - 12
  // ============================================================

  Car(
    id: 73,
    name: 'X50 بريميوم',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour X50 Premium.',
  ),

  Car(
    id: 74,
    name: 'JETOUR X70 Comfort 7 Seats',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour X70 Comfort.',
  ),

  Car(
    id: 75,
    name: 'JETOUR X70 Lux 7 Seats',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour X70 Lux.',
  ),

  Car(
    id: 76,
    name: 'Dashing 1600 LUX',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour Dashing 1600 LUX.',
  ),

  Car(
    id: 77,
    name: 'جيتور T1 كمفورت 2.0',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T1 Comfort.',
  ),

  Car(
    id: 78,
    name: 'جيتور T1 لاكشري 2.0',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T1 Luxury.',
  ),

  Car(
    id: 79,
    name: 'جيتور T2 لاكشري 2.0 بلس اللون الاسود',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T2 Luxury.',
  ),

  Car(
    id: 80,
    name: 'جيتور T2 لاكشري 2.0',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2027',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T2 Luxury.',
  ),

  Car(
    id: 81,
    name: 'جيتور T2 لاكشري 2.0 اسود مط',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2027',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour T2 Luxury.',
  ),

  Car(
    id: 82,
    name: 'جيتور G700 Comfort 7 Seats COM',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour G700 Comfort.',
  ),

  Car(
    id: 83,
    name: 'جيتور G700  LUX 6 مقاعد',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/g700lux1.jpeg',
            
    description: 'Jetour G700 LUX.',
  ),

  Car(
    id: 84,
    name: 'جيتور G700 Flagship 6 مقاعد',
    brand: 'JETOUR',
    category: 'JETOUR',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar22.jpg',
    description: 'Jetour G700 Flagship.',
  ),

 
  // ============================================================
  // CHERY PRO - 5
  // ============================================================

  Car(
    id: 85,
    name: 'اريزو 5 كمفورت 1.5 سي سي',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Arrizo 5 Comfort.',
  ),

  Car(
    id: 86,
    name: 'تيجو 2 كمفورت 1.5 الشكل الجديد',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Tiggo 2.',
  ),

  Car(

    id: 87,
    name: 'تيجو 4 1.5 كمفورت',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Tiggo 4.',
  ),

  Car(
    id: 88,
    name: 'تيجو 4 1.5 فل كامل LUX',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Tiggo 4 LUX.',
  ),

  Car(
    id: 89,
    name: 'تيجو 7 كمفورت 1.5 ',
    brand: 'CHERY PRO',
    category: 'CHERY PRO',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar3.jpg',
    description: 'Chery Tiggo 7 Pro Max.',
  ),

  // ============================================================
  // MG - 5
  // ============================================================

  Car(
    id: 90,
    name: 'MG 5 Standard 1.5 الشكل القديم',
    brand: 'MG',
    category: 'MG',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG 5 1.5 الشكل القديم.',
  ),

  Car(
    id: 91,
    name: 'MG 5 Standard 1.5 الشكل الجديد',
    brand: 'MG',
    category: 'MG',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG 5 1.5 الشكل الجديد.',
  ),

  Car(
    id: 92,
    name: 'MG 5 Comfort 1.5 الشكل الجديد',
    brand: 'MG',
    category: 'MG',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG 5 Comfort.',
  ),

  Car(
    id: 93,
    name: 'MG ZS 1.5 فل كامل',
    brand: 'MG',
    category: 'MG',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG ZS 1.5.',
  ),

  Car(
    id: 94,
    name: 'MG ZS 1.3 فل كامل Turbo',
    brand: 'MG',
    category: 'MG',
    year: '2024',
    price: '56,500 ﷼',
    image: 'assets/youssefcar4.jpg',
    description: 'MG ZS 1.3 Turbo.',
  ),

  // ============================================================
  // JELLY - 2
  // ============================================================

  Car(
    id: 95,
    name: 'او كافانجو 2.0 فل كامل',
    brand: 'Jelly',
    category: 'JELLY',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'Jelly Okavango.',
  ),
  

  Car(
    id:96,
    name: 'ستاريا 2.0 نصف فل',
    brand: 'Jelly',
    category: 'JELLY',
    year: '2025',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'Jelly Staria.',
  ),

  // ============================================================
  // RELY - 1
  // ============================================================

  Car(
    id: 97,
    name: 'Rely Comfort 2.3 4x4 ديزل',
    brand: 'RELY',
    category: 'RELY',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'Rely 2.3 Diesel 4x4.',
  ),

  // ============================================================
  // JAC - 7
  // ============================================================

  Car(
    id: 98,
    name: 'جاك 2.0 ديزل 4x4 استاندر',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC 2.0 Diesel 4x4.',
  ),

  Car(
    id: 99,
    name: 'جاك 2.0 ديزل 4x4 فل كامل',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC 2.0 Diesel 4x4 Full.',
  ),

  Car(
    id: 100,
    name: 'ام زوم GB',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Emzoom GB.',
  ),

  Car(
    id: 101,
    name: 'ام زوم GL بلس',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Emzoom GL Plus.',
  ),

  Car(id: 102,
    name: 'ام زوم سبورت بلس',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Emzoom Sport Plus.',
  ),

  Car(
    id: 103,
    name: 'امباو GE',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Empow GE.',
  ),

  Car(
    id: 104,
    name: 'جيت امباو R 2.0',
    brand: 'JAC',
    category: 'JAC',
    year: '2026',
    price: '56,500 ﷼',
    image: 'assets/youssefcar5.jpg',
    description: 'JAC Empow R 2.0.',
  ),
];

