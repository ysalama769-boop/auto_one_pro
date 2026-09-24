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
        .select(
          'color_id, is_available, image, exterior_images, interior_images, colors(id, name_ar, name_en, color_value)',
        )
        .eq('car_id', carId)
        .eq('is_available', true);

    return (response as List)
        .where((row) => row['colors'] != null)
        .map((row) {
          final baseColor =
              CarColor.fromMap(row['colors'] as Map<String, dynamic>);
          final colorImage = row['image'] as String?;
          return CarColor(
            id: baseColor.id,
            nameAr: baseColor.nameAr,
            nameEn: baseColor.nameEn,
            colorValue: baseColor.colorValue,
            image: (colorImage != null && colorImage.trim().isNotEmpty)
                ? colorImage.trim()
                : null,
            exteriorImages: (row['exterior_images'] is List)
                ? List<String>.from(
                    (row['exterior_images'] as List)
                        .map((e) => e.toString()),
                  )
                : const [],
            interiorImages: (row['interior_images'] is List)
                ? List<String>.from(
                    (row['interior_images'] as List)
                        .map((e) => e.toString()),
                  )
                : const [],
          );
        })
        .toList();
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل ألوان السيارة $carId: $e');
    return [];
  }
}


// بتجيب ألوان كل السيارات دفعة واحدة (طلب واحد بس، مش طلب لكل سيارة)
Future<void> loadColorsForCars(List<Car> carsList) async {
  try {
    final carIds = carsList.map((c) => c.id).whereType<int>().toList();
    if (carIds.isEmpty) return;

    final response = await Supabase.instance.client
        .from('car_color_availability')
        .select(
          'car_id, color_id, is_available, image, exterior_images, interior_images, colors(id, name_ar, name_en, color_value)',
        )
        .eq('is_available', true)
        .inFilter('car_id', carIds);

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
        exteriorImages: (map['exterior_images'] is List)
            ? List<String>.from(
                (map['exterior_images'] as List).map((e) => e.toString()),
              )
            : const [],
        interiorImages: (map['interior_images'] is List)
            ? List<String>.from(
                (map['interior_images'] as List).map((e) => e.toString()),
              )
            : const [],
      );
      grouped.putIfAbsent(carId, () => []).add(color);
    }

    // بنضيف للكاش الموجود بدل ما نستبدله بالكامل، عشان لو الدالة
    // دي اتنادت أكتر من مرة (تحميل دفعة تانية من السيارات) الألوان
    // القديمة متتمسحش.
    carColorsCache = {...carColorsCache, ...grouped};
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل الألوان: $e');
  }
}


// ============================================================
// CAR IMAGES CACHE (loaded from Supabase, bulk query)
// ============================================================
// بتخزن كل صور معرض كل سيارة حسب الـ id بتاعها
Map<int, List<String>> carImagesCache = {};


// بتجيب صور السيارات اللي في carsList بس (مش كل السيارات في
// قاعدة البيانات)، دفعة واحدة (طلب واحد بس)
Future<void> loadImagesForCars(List<Car> carsList) async {
  try {
    final carIds = carsList.map((c) => c.id).whereType<int>().toList();
    if (carIds.isEmpty) return;

    final response = await Supabase.instance.client
        .from('car_images')
        .select('car_id, image')
        .inFilter('car_id', carIds);

    final Map<int, List<String>> grouped = {};

    for (final row in (response as List)) {
      final map = row as Map<String, dynamic>;
      final carId = map['car_id'] as int?;
      final image = map['image'] as String?;
      if (carId == null || image == null || image.isEmpty) continue;

      grouped.putIfAbsent(carId, () => []).add(image);
    }

    // بنضيف للكاش الموجود بدل ما نستبدله، لنفس سبب الألوان فوق
    carImagesCache = {...carImagesCache, ...grouped};
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل صور المعرض: $e');
  }
}

// ============================================================
// FINANCING PARTNERS (جهات التمويل المعتمدة)
// ============================================================
List<Map<String, dynamic>> financingPartnersCache = [];

Future<void> loadFinancingPartners() async {
  try {
    final response = await Supabase.instance.client
        .from('financing_partners')
        .select()
        .order('id');
    financingPartnersCache = List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل جهات التمويل: $e');
  }
}

// شعار كل ماركة (اسم الماركة بالإنجليزي → رابط الصورة)، مستخدم
// في أي مكان محتاج يعرض شعارات الماركات (شريط الماركات في
// الرئيسية، عمود الفلترة في صفحة السيارات...)
Map<String, String> brandLogosCache = {};

Future<void> loadBrandLogos() async {
  try {
    final response = await Supabase.instance.client
        .from('brands')
        .select('name_en, logo');
    final rows = List<Map<String, dynamic>>.from(response as List);
    brandLogosCache = {
      for (final row in rows)
        if ((row['name_en'] ?? '').toString().trim().isNotEmpty)
          (row['name_en'] as String).trim(): (row['logo'] ?? '').toString(),
    };
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل شعارات الماركات: $e');
  }
}

// ============================================================
// CUSTOMER REVIEWS (تقييمات العملاء - الموافَق عليها بس)
// ============================================================
List<Map<String, dynamic>> approvedReviewsCache = [];

Future<void> loadApprovedReviews() async {
  try {
    final response = await Supabase.instance.client
        .from('customer_reviews')
        .select()
        .eq('status', 'approved')
        .order('created_at', ascending: false);
    approvedReviewsCache = List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل تقييمات العملاء: $e');
  }
}

Future<void> submitCustomerReview({
  required String customerName,
  required String reviewText,
  int? carId,
}) async {
  await Supabase.instance.client.from('customer_reviews').insert({
    'customer_name': customerName,
    'review_text': reviewText,
    'status': 'pending',
    if (carId != null) 'car_id': carId,
  });
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
// بتجيب سيارة واحدة بالـ id مباشرة من قاعدة البيانات — مستخدمة
// لما حد يفتح رابط مشاركة لسيارة ممكن متكونش لسه من ضمن الدفعة
// المتحمّلة (أول carsPageSize سيارة) في القايمة العامة cars.
Future<Car?> fetchCarById(int id) async {
  try {
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
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    final car = Car.fromMap(response);
    await Future.wait([
      loadColorsForCars([car]),
      loadImagesForCars([car]),
    ]);
    return car;
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل السيارة رقم $id: $e');
    return null;
  }
}

// أول عدد سيارات بيتحمّل لأي صفحة (سريع)، والباقي بيتحمّل بعدين
// دفعة دفعة (20 سيارة كل مرة) لما حد يفتح صفحة "تصفّح السيارات"
const int carsPageSize = 20;

// بيتتبّع عدد السيارات اللي اتحمّلت لحد دلوقتي، وهل فيه سيارات
// تانية لسه معملهاش تحميل ولا خلصوا كلهم
int _carsLoadedOffset = 0;
bool hasMoreCarsToLoad = true;

Future<void> loadCarsFromSupabase() async {
  try {
    // بنجيب بس الأعمدة اللي محتاجينها لعرض كروت السيارات في الصفحة
    // الرئيسية وقائمة السيارات (مش كل تفاصيل السيارة زي الأبعاد
    // والمواصفات الكاملة)، وده بيقلل حجم البيانات اللي بتتحمّل بشكل
    // كبير خصوصًا مع عدد كبير من السيارات. التفاصيل الكاملة بتتحمّل
    // بعدين لما حد يفتح صفحة سيارة معيّنة (CarDetailsPage).
    //
    // وكمان بنجيب أول carsPageSize سيارة بس هنا (مش كل السيارات
    // دفعة واحدة)، عشان الموقع يفتح بسرعة — الباقي بيتحمّل بعدين
    // دفعة دفعة لما حد يفتح صفحة "تصفّح السيارات" (loadMoreCars).
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
        .order('sort_order', nullsFirst: false)
        .range(0, carsPageSize - 1);

    debugPrint('AUTO_ONE_DEBUG: raw response = $response');

    final fetched = (response as List)
        .map((row) => Car.fromMap(row as Map<String, dynamic>))
        .toList();

    debugPrint('AUTO_ONE_DEBUG: fetched ${fetched.length} cars from Supabase');

    if (fetched.isNotEmpty) {
      cars = fetched;
      _carsLoadedOffset = fetched.length;
      hasMoreCarsToLoad = fetched.length == carsPageSize;
      debugPrint('AUTO_ONE_DEBUG: cars list replaced successfully');
      await Future.wait([
        loadColorsForCars(fetched),
        loadImagesForCars(fetched),
        loadFinancingPartners(),
        loadApprovedReviews(),
      ]);
      debugPrint('AUTO_ONE_DEBUG: colors loaded for ${carColorsCache.length} cars, images loaded for ${carImagesCache.length} cars');
    } else {
      debugPrint('AUTO_ONE_DEBUG: fetched list was empty, cars list stays empty');
      hasMoreCarsToLoad = false;
    }
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: EXCEPTION while loading cars: $e');
  }
}

// بتجيب دفعة تانية (20 سيارة) وتضيفها لقايمة cars الموجودة، من
// غير ما تمسح اللي اتحمّل قبل كده. بترجع true لو فعلاً جابت
// سيارات جديدة، و false لو خلصت كل السيارات أو حصل خطأ.
Future<bool> loadMoreCars() async {
  if (!hasMoreCarsToLoad) return false;

  try {
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
        .order('sort_order', nullsFirst: false)
        .range(_carsLoadedOffset, _carsLoadedOffset + carsPageSize - 1);

    final fetched = (response as List)
        .map((row) => Car.fromMap(row as Map<String, dynamic>))
        .toList();

    if (fetched.isEmpty) {
      hasMoreCarsToLoad = false;
      return false;
    }

    cars = [...cars, ...fetched];
    _carsLoadedOffset += fetched.length;
    hasMoreCarsToLoad = fetched.length == carsPageSize;

    await Future.wait([
      loadColorsForCars(fetched),
      loadImagesForCars(fetched),
    ]);

    return true;
  } catch (e) {
    debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل دفعة سيارات إضافية: $e');
    return false;
  }
}


// ============================================================
// المخزون الحقيقي — بيتحمّل بالكامل من Supabase (loadCarsFromSupabase)
// مفيش بيانات وهمية ثابتة هنا؛ لو التحميل فشل، الواجهة بتوري
// رسالة "تعذّر تحميل السيارات" بدل ما تعرض بيانات قديمة غلط.
// ============================================================

List<Car> cars = [];

