// ============================================================
// مواصفات السيارة الإضافية — تعريف موحّد
//
// ده "المصدر الوحيد للحقيقة" لكل الـ40 بند الجديدة اللي اتفقنا
// عليها (بعيدًا عن الـ17 بند الموجودة أصلاً في نموذج السيارة
// زي الوقود والناقل والمحرك...). لوحة التحكم وصفحة تفاصيل
// السيارة للزبائن بيقروا من نفس القايمة دي، عشان أي إضافة أو
// تعديل تحصل مرة واحدة بس هنا وتنعكس في المكانين تلقائي.
//
// كل سيارة بتخزن قيم البنود دي في عمود واحد jsonb اسمه
// extra_specs، شكله: { "cylinder_count": "6", "isofix": true, ... }
// — أي بند مش موجود كـ key في الـ map يبقى معناه "مش متوفرة في
// السيارة دي" ومش بيتعرض خالص.
// ============================================================

enum CarSpecType {
  // بند نعم/لأ بس (زي ISOFIX) — وجود الـ key بقيمة true معناه متوفر
  toggle,
  // بند باختيار واحد من قايمة جاهزة (زي نوع المصابيح)
  choice,
  // بند باختيار أكتر من قيمة من قايمة جاهزة (زي مميزات المرايا)
  multiChoice,
}

class CarSpecOption {
  final String value; // القيمة المخزّنة فعليًا
  final String labelAr;
  final String labelEn;

  const CarSpecOption({
    required this.value,
    required this.labelAr,
    required this.labelEn,
  });
}

class CarSpecItem {
  final String key; // اسم الحقل جوه extra_specs
  final String labelAr;
  final String labelEn;
  final CarSpecType type;
  final List<CarSpecOption> options; // فاضية لو النوع toggle
  final String? unitAr; // كلمة وحدة ثابتة تتحط بعد القيمة (زي "سلندر")
  final String? unitEn;

  const CarSpecItem({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.type,
    this.options = const [],
    this.unitAr,
    this.unitEn,
  });
}

class CarSpecCategory {
  final String key;
  final String labelAr;
  final String labelEn;
  final List<CarSpecItem> items;

  const CarSpecCategory({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.items,
  });
}

const List<CarSpecCategory> carSpecCategories = [
  CarSpecCategory(
    key: 'engine',
    labelAr: 'المحرك',
    labelEn: 'Engine',
    items: [
      CarSpecItem(
        key: 'cylinder_count',
        labelAr: 'عدد الأسطوانات',
        labelEn: 'Cylinder Count',
        type: CarSpecType.choice,
        unitAr: 'سلندر',
        unitEn: 'cyl',
        options: [
          CarSpecOption(value: '3', labelAr: '3', labelEn: '3'),
          CarSpecOption(value: '4', labelAr: '4', labelEn: '4'),
          CarSpecOption(value: '6', labelAr: '6', labelEn: '6'),
          CarSpecOption(value: '8', labelAr: '8', labelEn: '8'),
          CarSpecOption(value: '12', labelAr: '12', labelEn: '12'),
        ],
      ),
    ],
  ),
  CarSpecCategory(
    key: 'lighting',
    labelAr: 'الإضاءة',
    labelEn: 'Lighting',
    items: [
      CarSpecItem(
        key: 'headlights_type',
        labelAr: 'مصابيح أمامية',
        labelEn: 'Headlights',
        type: CarSpecType.choice,
        options: [
          CarSpecOption(value: 'led', labelAr: 'LED', labelEn: 'LED'),
          CarSpecOption(value: 'xenon', labelAr: 'زينون', labelEn: 'Xenon'),
          CarSpecOption(
              value: 'matrix', labelAr: 'ماتريكس', labelEn: 'Matrix'),
          CarSpecOption(value: 'laser', labelAr: 'ليزر', labelEn: 'Laser'),
        ],
      ),
      CarSpecItem(
        key: 'drl',
        labelAr: 'إضاءة نهارية (DRL)',
        labelEn: 'Daytime Running Lights',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'taillights_type',
        labelAr: 'مصابيح خلفية',
        labelEn: 'Taillights',
        type: CarSpecType.choice,
        options: [
          CarSpecOption(value: 'led', labelAr: 'LED', labelEn: 'LED'),
          CarSpecOption(
              value: 'halogen', labelAr: 'هالوجين', labelEn: 'Halogen'),
        ],
      ),
      CarSpecItem(
        key: 'fog_lights',
        labelAr: 'كشافات ضباب',
        labelEn: 'Fog Lights',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'adaptive_cornering_lights',
        labelAr: 'إضاءة تكيفية للمنعطفات',
        labelEn: 'Adaptive Cornering Lights',
        type: CarSpecType.toggle,
      ),
    ],
  ),
  CarSpecCategory(
    key: 'exterior',
    labelAr: 'الهيكل الخارجي',
    labelEn: 'Exterior',
    items: [
      CarSpecItem(
        key: 'wheels_type',
        labelAr: 'الجنوط',
        labelEn: 'Wheels',
        type: CarSpecType.choice,
        options: [
          CarSpecOption(
              value: 'steel', labelAr: 'جنوط معدنية', labelEn: 'Steel'),
          CarSpecOption(
              value: 'alloy', labelAr: 'جنوط ألمنيوم', labelEn: 'Alloy'),
        ],
      ),
      CarSpecItem(
        key: 'mirrors_features',
        labelAr: 'مميزات المرايا',
        labelEn: 'Mirror Features',
        type: CarSpecType.multiChoice,
        options: [
          CarSpecOption(
              value: 'electric', labelAr: 'كهربائية', labelEn: 'Electric'),
          CarSpecOption(
              value: 'foldable',
              labelAr: 'قابلة للطي',
              labelEn: 'Foldable'),
          CarSpecOption(
              value: 'heated', labelAr: 'تدفئة', labelEn: 'Heated'),
          CarSpecOption(
              value: 'memory', labelAr: 'ذاكرة', labelEn: 'Memory'),
        ],
      ),
      CarSpecItem(
        key: 'smart_entry',
        labelAr: 'مقابض أبواب بدخول ذكي',
        labelEn: 'Smart Entry Door Handles',
        type: CarSpecType.toggle,
      ),
    ],
  ),
  CarSpecCategory(
    key: 'basic_safety',
    labelAr: 'الأمان الأساسي',
    labelEn: 'Basic Safety',
    items: [
      CarSpecItem(
        key: 'esc',
        labelAr: 'نظام التحكم بالثبات (ESC)',
        labelEn: 'Electronic Stability Control',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'tpms',
        labelAr: 'مراقبة ضغط الإطارات',
        labelEn: 'Tire Pressure Monitoring',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'ebd',
        labelAr: 'توزيع قوة الفرملة (EBD)',
        labelEn: 'Electronic Brakeforce Distribution',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'ba',
        labelAr: 'مساعد الفرملة (BA)',
        labelEn: 'Brake Assist',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'trc',
        labelAr: 'التحكم بالجر (TRC)',
        labelEn: 'Traction Control',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'seatbelts_type',
        labelAr: 'أحزمة الأمان',
        labelEn: 'Seatbelts',
        type: CarSpecType.choice,
        options: [
          CarSpecOption(
              value: 'three_point',
              labelAr: 'ثلاثية النقاط',
              labelEn: 'Three-point'),
          CarSpecOption(
              value: 'force_limiter',
              labelAr: 'بمحدد قوة',
              labelEn: 'Force limiter'),
          CarSpecOption(
              value: 'pretensioner',
              labelAr: 'بشداد',
              labelEn: 'Pretensioner'),
        ],
      ),
      CarSpecItem(
        key: 'isofix',
        labelAr: 'ISOFIX',
        labelEn: 'ISOFIX',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'anti_theft_alarm',
        labelAr: 'إنذار سرقة',
        labelEn: 'Anti-theft Alarm',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'central_locking',
        labelAr: 'إغلاق مركزي',
        labelEn: 'Central Locking',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'child_lock',
        labelAr: 'قفل أطفال',
        labelEn: 'Child Lock',
        type: CarSpecType.toggle,
      ),
    ],
  ),
  CarSpecCategory(
    key: 'adas',
    labelAr: 'أنظمة السلامة المتقدمة',
    labelEn: 'Advanced Safety (ADAS)',
    items: [
      CarSpecItem(
        key: 'lane_keep_assist',
        labelAr: 'متابعة المسار',
        labelEn: 'Lane Keep Assist',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'auto_emergency_braking',
        labelAr: 'الفرامل التلقائية الطارئة',
        labelEn: 'Auto Emergency Braking',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'adaptive_cruise_control',
        labelAr: 'تثبيت السرعة التكيفي',
        labelEn: 'Adaptive Cruise Control',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'camera_360',
        labelAr: 'كاميرا 360 درجة',
        labelEn: '360° Camera',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'lane_departure_warning',
        labelAr: 'تنبيه مغادرة المسار',
        labelEn: 'Lane Departure Warning',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'blind_spot_warning',
        labelAr: 'تحذير النقطة العمياء',
        labelEn: 'Blind Spot Warning',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'parking_assist',
        labelAr: 'مساعد صف السيارات',
        labelEn: 'Parking Assist',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'forward_collision_warning',
        labelAr: 'تحذير الاصطدام الأمامي',
        labelEn: 'Forward Collision Warning',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'driver_monitoring',
        labelAr: 'مراقبة سائق (كشف النعاس)',
        labelEn: 'Driver Monitoring',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'auto_high_beam',
        labelAr: 'مساعد الإضاءة العالية التلقائي',
        labelEn: 'Auto High Beam Assist',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'rear_cross_traffic_alert',
        labelAr: 'تنبيه حركة المرور الخلفية',
        labelEn: 'Rear Cross Traffic Alert',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'hill_descent_ascent_assist',
        labelAr: 'مساعد صعود/نزول المرتفعات',
        labelEn: 'Hill Descent/Ascent Assist',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'head_up_display',
        labelAr: 'Head-Up Display',
        labelEn: 'Head-Up Display',
        type: CarSpecType.toggle,
      ),
    ],
  ),
  CarSpecCategory(
    key: 'comfort',
    labelAr: 'الراحة الداخلية',
    labelEn: 'Interior Comfort',
    items: [
      CarSpecItem(
        key: 'seats_material',
        labelAr: 'نوع المقاعد',
        labelEn: 'Seats Material',
        type: CarSpecType.choice,
        options: [
          CarSpecOption(value: 'leather', labelAr: 'جلد', labelEn: 'Leather'),
          CarSpecOption(value: 'fabric', labelAr: 'قماش', labelEn: 'Fabric'),
          CarSpecOption(
              value: 'synthetic_leather',
              labelAr: 'جلد صناعي',
              labelEn: 'Synthetic leather'),
        ],
      ),
      CarSpecItem(
        key: 'seats_heating_cooling',
        labelAr: 'تدفئة/تبريد المقاعد',
        labelEn: 'Seat Heating/Cooling',
        type: CarSpecType.choice,
        options: [
          CarSpecOption(
              value: 'heating', labelAr: 'تدفئة فقط', labelEn: 'Heating only'),
          CarSpecOption(
              value: 'cooling', labelAr: 'تبريد فقط', labelEn: 'Cooling only'),
          CarSpecOption(
              value: 'both',
              labelAr: 'تدفئة وتبريد',
              labelEn: 'Heating & cooling'),
        ],
      ),
      CarSpecItem(
        key: 'seats_adjustment',
        labelAr: 'تعديل المقاعد',
        labelEn: 'Seat Adjustment',
        type: CarSpecType.choice,
        options: [
          CarSpecOption(value: 'manual', labelAr: 'يدوي', labelEn: 'Manual'),
          CarSpecOption(
              value: 'electric', labelAr: 'كهربائي', labelEn: 'Electric'),
          CarSpecOption(
              value: 'electric_memory',
              labelAr: 'كهربائي بذاكرة',
              labelEn: 'Electric with memory'),
        ],
      ),
    ],
  ),
  CarSpecCategory(
    key: 'entertainment',
    labelAr: 'الترفيه والتقنية',
    labelEn: 'Entertainment & Tech',
    items: [
      CarSpecItem(
        key: 'screen_size',
        labelAr: 'مقاس الشاشة',
        labelEn: 'Screen Size',
        type: CarSpecType.choice,
        options: [
          CarSpecOption(value: '7', labelAr: '7 بوصة', labelEn: '7"'),
          CarSpecOption(value: '8', labelAr: '8 بوصة', labelEn: '8"'),
          CarSpecOption(value: '10', labelAr: '10 بوصة', labelEn: '10"'),
          CarSpecOption(value: '12.3', labelAr: '12.3 بوصة', labelEn: '12.3"'),
          CarSpecOption(
              value: '12+', labelAr: 'أكبر من 12 بوصة', labelEn: 'Over 12"'),
        ],
      ),
      CarSpecItem(
        key: 'apple_carplay',
        labelAr: 'Apple CarPlay',
        labelEn: 'Apple CarPlay',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'android_auto',
        labelAr: 'Android Auto',
        labelEn: 'Android Auto',
        type: CarSpecType.toggle,
      ),
      CarSpecItem(
        key: 'sound_system',
        labelAr: 'النظام الصوتي',
        labelEn: 'Sound System',
        type: CarSpecType.choice,
        options: [
          CarSpecOption(value: 'standard', labelAr: 'عادي', labelEn: 'Standard'),
          CarSpecOption(
              value: 'premium', labelAr: 'بريميوم', labelEn: 'Premium'),
        ],
      ),
    ],
  ),
  CarSpecCategory(
    key: 'cabin',
    labelAr: 'المقصورة',
    labelEn: 'Cabin',
    items: [
      CarSpecItem(
        key: 'power_trunk',
        labelAr: 'فتح الصندوق كهربائي',
        labelEn: 'Power Trunk',
        type: CarSpecType.toggle,
      ),
    ],
  ),
];

// دالة مساعدة: تجيب تعريف بند بالـ key بتاعه
CarSpecItem? findCarSpecItem(String key) {
  for (final category in carSpecCategories) {
    for (final item in category.items) {
      if (item.key == key) return item;
    }
  }
  return null;
}

// دالة مساعدة: تجيب مفتاح القسم اللي بند معيّن تابع له
String? findCarSpecCategoryKey(String itemKey) {
  for (final category in carSpecCategories) {
    for (final item in category.items) {
      if (item.key == itemKey) return category.key;
    }
  }
  return null;
}
