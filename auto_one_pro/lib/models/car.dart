
// ============================================================
// CAR COLOR
// ============================================================

class CarColor {
  final String id;
  final String nameAr;
  final String nameEn;
  final int colorValue;
  // صورة السيارة باللون ده تحديدًا (لو موجودة)
  final String? image;

  const CarColor({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.colorValue,
    this.image,
  });

  // بيحول صف جاي من جدول colors في Supabase لكائن CarColor
  factory CarColor.fromMap(Map<String, dynamic> map) {
    final rawValue = (map['color_value'] as int?) ?? 0xFFFFFF;
    return CarColor(
      id: map['id'].toString(),
      nameAr: (map['name_ar'] ?? '') as String,
      nameEn: (map['name_en'] ?? '') as String,
      // بنضيف قناة الشفافية (alpha) لأن القيمة في القاعدة مخزنة من غيرها
      colorValue: 0xFF000000 | rawValue,
    );
  }
}


// ============================================================
// CAR MODEL
// ============================================================

class Car {
  final int? id;
  final String name;
  final String brand;
  final String category;
  final String year;
  final String price;

  

  final String image;
  final List<String> images;
  final String description;
  final String nameEn;
  final String descriptionEn;

  // اسم/وصف السيارة بالمظهر المناسب للغة الحالية
  // (لو الإنجليزي فاضي، بيرجع النسخة العربية بدلاً منه)
  String displayName(bool isArabic) =>
      (!isArabic && nameEn.trim().isNotEmpty) ? nameEn : name;
  String displayDescription(bool isArabic) =>
      (!isArabic && descriptionEn.trim().isNotEmpty)
          ? descriptionEn
          : description;

  // ==========================================================
  // BASIC SPECIFICATIONS
  // ==========================================================

  final String engine;
  final String transmission;
  final String fuel;
  final String seats;
  final String drive;

  // ==========================================================
  // DIMENSIONS
  // ==========================================================

  final String carLength;
  final String carWidth;
  final String carHeight;
  final String wheelbase;
  final String trunkCapacity;

  // ==========================================================
  // EXTRA DRIVING SPECS
  // ==========================================================

  final String horsepower;
  final String torque;
  final String fuelTank;
  final String fuelConsumption;

  // ==========================================================
  // FEATURES
  // ==========================================================

  final String infotainment;
  final String sunroof;
  final String cameraSensors;
  final String wirelessCharger;

  // ==========================================================
  // SAFETY
  // ==========================================================

  final String airbags;
  final String absSystem;

  // ==========================================================
  // MASTER SPECIFICATIONS
  // ==========================================================

  final List<String> specifications;

  // ==========================================================
  // OPTIONS
  // ==========================================================

  final List<String> options;

  // ==========================================================
  // AVAILABLE COLORS
  // ==========================================================

  final List<String> availableColorIds;
  final Map<String, String> colorImages;
  // ==========================================================
  // OFFER
  // ==========================================================

  final bool isOffer;
  final String oldPrice;
  final String discountPercent;
  final String offerStartDate;
  final String offerEndDate;
  final bool isFeatured;
  final int viewCount;

  // العرض يعتبر شغال لو isOffer=true وتاريخ النهاية (لو موجود) لسه ماجاش
  bool get isOfferActive {
    if (!isOffer) return false;
    if (offerEndDate.trim().isEmpty) return true;
    final end = DateTime.tryParse(offerEndDate.trim());
    if (end == null) return true;
    final today = DateTime.now();
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return !today.isAfter(endOfDay);
  }

  // ==========================================================
  // EXTRA SPECS (flexible key → value, e.g. "ACC": "نعم")
  // ==========================================================
  final Map<String, String> extraSpecs;

  // ==========================================================
  // STATUS + INVENTORY
  // ==========================================================
  final String carStatus; // available | reserved | sold
  final String vin;
  final String plateNumber;
  final String location;
  final String arrivalDate;
  final String conditionStatus; // new | used

  const Car({
     this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.year,
    required this.price,
    
    
    required this.image,
    this.images = const [],
    required this.description,
    this.nameEn = '',
    this.descriptionEn = '',

    // Basic specifications
    this.engine = '1.5L',
    this.transmission = 'أوتوماتيك',
    this.fuel = 'بنزين',
    this.seats = '5',
    this.drive = 'دفع أمامي',

    // Dimensions
    this.carLength = '',
    this.carWidth = '',
    this.carHeight = '',
    this.wheelbase = '',
    this.trunkCapacity = '',

    // Extra driving specs
    this.horsepower = '',
    this.torque = '',
    this.fuelTank = '',
    this.fuelConsumption = '',

    // Features
    this.infotainment = '',
    this.sunroof = '',
    this.cameraSensors = '',
    this.wirelessCharger = '',

    // Safety
    this.airbags = '',
    this.absSystem = '',

    
    // Master specifications
    this.specifications = const [],

    // Options
    this.options = const [],

   // Colors
  this.availableColorIds = const [],
  this.colorImages = const {},

    // Offer
    this.isOffer = false,
    this.oldPrice = '',
    this.discountPercent = '',
    this.offerStartDate = '',
    this.offerEndDate = '',
    this.isFeatured = false,
    this.viewCount = 0,

    // Extra specs
    this.extraSpecs = const {},

    // Status + inventory
    this.carStatus = 'available',
    this.vin = '',
    this.plateNumber = '',
    this.location = '',
    this.arrivalDate = '',
    this.conditionStatus = 'new',
  });

  // ==========================================================
  // FROM SUPABASE
  // ==========================================================
  // بيحول صف (row) جاي من جدول cars في Supabase لكائن Car
  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      brand: (map['brand'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      year: (map['year'] ?? '') as String,
      price: (map['price'] ?? '') as String,
      image: (map['image'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      nameEn: (map['name_en'] ?? '') as String,
      descriptionEn: (map['description_en'] ?? '') as String,
      engine: (map['engine'] ?? '1.5L') as String,
      transmission: (map['transmission'] ?? 'أوتوماتيك') as String,
      fuel: (map['fuel'] ?? 'بنزين') as String,
      seats: (map['seats'] ?? '5') as String,
      drive: (map['drive'] ?? 'دفع أمامي') as String,
      carLength: (map['car_length'] ?? '') as String,
      carWidth: (map['car_width'] ?? '') as String,
      carHeight: (map['car_height'] ?? '') as String,
      wheelbase: (map['wheelbase'] ?? '') as String,
      trunkCapacity: (map['trunk_capacity'] ?? '') as String,
      horsepower: (map['horsepower'] ?? '') as String,
      torque: (map['torque'] ?? '') as String,
      fuelTank: (map['fuel_tank'] ?? '') as String,
      fuelConsumption: (map['fuel_consumption'] ?? '') as String,
      infotainment: (map['infotainment'] ?? '') as String,
      sunroof: (map['sunroof'] ?? '') as String,
      cameraSensors: (map['camera_sensors'] ?? '') as String,
      wirelessCharger: (map['wireless_charger'] ?? '') as String,
      airbags: (map['airbags'] ?? '') as String,
      absSystem: (map['abs_system'] ?? '') as String,
      isOffer: (map['is_offer'] ?? false) as bool,
      oldPrice: (map['old_price'] ?? '') as String,
      discountPercent: (map['discount_percent'] ?? '') as String,
      offerStartDate: (map['offer_start_date'] ?? '').toString(),
      offerEndDate: (map['offer_end_date'] ?? '').toString(),
      isFeatured: (map['is_featured'] ?? false) as bool,
      viewCount: (map['view_count'] ?? 0) as int,
      extraSpecs: (map['extra_specs'] is Map)
          ? Map<String, String>.from(
              (map['extra_specs'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            )
          : const {},
      carStatus: (map['car_status'] ?? 'available') as String,
      vin: (map['vin'] ?? '') as String,
      plateNumber: (map['plate_number'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      arrivalDate: (map['arrival_date'] ?? '') as String,
      conditionStatus: (map['condition_status'] ?? 'new') as String,
    );
  }
}

