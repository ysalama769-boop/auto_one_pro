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

import 'package:flutter/material.dart';

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
  final IconData icon; // أيقونة توضيحية للبند، تُستخدم في عرض العميل
  // لو مش null، معناها إن البند ده قديم وقيمته بتتخزن في عمود
  // حقيقي في جدول cars (مش جوه extra_specs) — زي 'fuel' أو
  // 'transmission'. الأغلبية (البنود الجديدة) قيمتها null هنا.
  final String? storesInColumn;

  const CarSpecItem({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.type,
    this.options = const [],
    this.unitAr,
    this.unitEn,
    this.icon = Icons.check_circle_outline_rounded,
    this.storesInColumn,
  });
}

class CarSpecCategory {
  final String key;
  final String labelAr;
  final String labelEn;
  final IconData icon;
  final Color color;
  final List<CarSpecItem> items;

  const CarSpecCategory({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    required this.color,
    required this.items,
  });
}

const List<CarSpecCategory> carSpecCategories = [
  CarSpecCategory(
    key: 'engine',
    labelAr: 'المحرك',
    labelEn: 'Engine',
    icon: Icons.settings_rounded,
    color: Color(0xFF378ADD),
    items: [
      CarSpecItem(
        key: 'fuel',
        labelAr: 'نوع الوقود',
        labelEn: 'Fuel Type',
        type: CarSpecType.choice,
        icon: Icons.local_gas_station_rounded,
        storesInColumn: 'fuel',
        options: [
          CarSpecOption(value: 'بنزين', labelAr: 'بنزين', labelEn: 'Petrol'),
          CarSpecOption(value: 'ديزل', labelAr: 'ديزل', labelEn: 'Diesel'),
          CarSpecOption(value: 'هجين', labelAr: 'هجين', labelEn: 'Hybrid'),
          CarSpecOption(
              value: 'كهربائي', labelAr: 'كهربائي', labelEn: 'Electric'),
        ],
      ),
      CarSpecItem(
        key: 'transmission',
        labelAr: 'ناقل الحركة',
        labelEn: 'Transmission',
        type: CarSpecType.choice,
        icon: Icons.settings_input_component_rounded,
        storesInColumn: 'transmission',
        options: [
          CarSpecOption(value: 'يدوي', labelAr: 'يدوي', labelEn: 'Manual'),
          CarSpecOption(
              value: 'أوتوماتيك',
              labelAr: 'أوتوماتيك',
              labelEn: 'Automatic'),
          CarSpecOption(value: 'CVT', labelAr: 'CVT', labelEn: 'CVT'),
          CarSpecOption(value: 'DCT', labelAr: 'DCT', labelEn: 'DCT'),
        ],
      ),
      CarSpecItem(
        key: 'drive',
        labelAr: 'نظام الدفع',
        labelEn: 'Drivetrain',
        type: CarSpecType.choice,
        icon: Icons.route_rounded,
        storesInColumn: 'drive',
        options: [
          CarSpecOption(
              value: 'دفع أمامي', labelAr: 'دفع أمامي', labelEn: 'FWD'),
          CarSpecOption(
              value: 'دفع خلفي', labelAr: 'دفع خلفي', labelEn: 'RWD'),
          CarSpecOption(
              value: 'رباعي دائم', labelAr: 'رباعي دائم', labelEn: 'AWD'),
          CarSpecOption(
              value: 'رباعي قابل للتفعيل',
              labelAr: 'رباعي قابل للتفعيل',
              labelEn: '4WD'),
        ],
      ),
      CarSpecItem(
        key: 'cylinder_count',
        labelAr: 'عدد الأسطوانات',
        labelEn: 'Cylinder Count',
        type: CarSpecType.choice,
        icon: Icons.speed_rounded,
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
    icon: Icons.lightbulb_rounded,
    color: Color(0xFFEF9F27),
    items: [
      CarSpecItem(
        key: 'headlights_type',
        labelAr: 'مصابيح أمامية',
        labelEn: 'Headlights',
        type: CarSpecType.choice,
        icon: Icons.wb_incandescent_rounded,
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
        icon: Icons.brightness_low_rounded,
      ),
      CarSpecItem(
        key: 'taillights_type',
        labelAr: 'مصابيح خلفية',
        labelEn: 'Taillights',
        type: CarSpecType.choice,
        icon: Icons.tungsten_rounded,
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
        icon: Icons.foggy,
      ),
      CarSpecItem(
        key: 'adaptive_cornering_lights',
        labelAr: 'إضاءة تكيفية للمنعطفات',
        labelEn: 'Adaptive Cornering Lights',
        type: CarSpecType.toggle,
        icon: Icons.turn_slight_right_rounded,
      ),
    ],
  ),
  CarSpecCategory(
    key: 'exterior',
    labelAr: 'الهيكل الخارجي',
    labelEn: 'Exterior',
    icon: Icons.directions_car_filled_rounded,
    color: Color(0xFF7F77DD),
    items: [
      CarSpecItem(
        key: 'sunroof',
        labelAr: 'فتحة سقف',
        labelEn: 'Sunroof',
        type: CarSpecType.choice,
        icon: Icons.wb_sunny_rounded,
        storesInColumn: 'sunroof',
        options: [
          CarSpecOption(value: 'عادية', labelAr: 'عادية', labelEn: 'Standard'),
          CarSpecOption(
              value: 'بانوراما', labelAr: 'بانوراما', labelEn: 'Panoramic'),
        ],
      ),
      CarSpecItem(
        key: 'wheels_type',
        labelAr: 'الجنوط',
        labelEn: 'Wheels',
        type: CarSpecType.choice,
        icon: Icons.album_rounded,
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
        icon: Icons.flip_to_front_rounded,
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
        icon: Icons.key_rounded,
      ),
    ],
  ),
  CarSpecCategory(
    key: 'basic_safety',
    labelAr: 'الأمان الأساسي',
    labelEn: 'Basic Safety',
    icon: Icons.shield_rounded,
    color: Color(0xFF639922),
    items: [
      CarSpecItem(
        key: 'airbags',
        labelAr: 'عدد الوسائد الهوائية',
        labelEn: 'Airbags',
        type: CarSpecType.choice,
        icon: Icons.airline_seat_recline_normal_rounded,
        unitAr: 'وسائد',
        unitEn: 'airbags',
        storesInColumn: 'airbags',
        options: [
          CarSpecOption(value: '2', labelAr: '2', labelEn: '2'),
          CarSpecOption(value: '4', labelAr: '4', labelEn: '4'),
          CarSpecOption(value: '6', labelAr: '6', labelEn: '6'),
          CarSpecOption(value: '8', labelAr: '8', labelEn: '8'),
          CarSpecOption(value: '10', labelAr: '10', labelEn: '10'),
        ],
      ),
      CarSpecItem(
        key: 'abs_system',
        labelAr: 'نظام ABS',
        labelEn: 'ABS',
        type: CarSpecType.toggle,
        icon: Icons.album_rounded,
        storesInColumn: 'abs_system',
      ),
      CarSpecItem(
        key: 'esc',
        labelAr: 'نظام التحكم بالثبات (ESC)',
        labelEn: 'Electronic Stability Control',
        type: CarSpecType.toggle,
        icon: Icons.balance_rounded,
      ),
      CarSpecItem(
        key: 'tpms',
        labelAr: 'مراقبة ضغط الإطارات',
        labelEn: 'Tire Pressure Monitoring',
        type: CarSpecType.toggle,
        icon: Icons.tire_repair_rounded,
      ),
      CarSpecItem(
        key: 'ebd',
        labelAr: 'توزيع قوة الفرملة (EBD)',
        labelEn: 'Electronic Brakeforce Distribution',
        type: CarSpecType.toggle,
        icon: Icons.equalizer_rounded,
      ),
      CarSpecItem(
        key: 'ba',
        labelAr: 'مساعد الفرملة (BA)',
        labelEn: 'Brake Assist',
        type: CarSpecType.toggle,
        icon: Icons.pan_tool_rounded,
      ),
      CarSpecItem(
        key: 'trc',
        labelAr: 'التحكم بالجر (TRC)',
        labelEn: 'Traction Control',
        type: CarSpecType.toggle,
        icon: Icons.grain_rounded,
      ),
      CarSpecItem(
        key: 'seatbelts_type',
        labelAr: 'أحزمة الأمان',
        labelEn: 'Seatbelts',
        type: CarSpecType.choice,
        icon: Icons.airline_seat_recline_normal_rounded,
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
        icon: Icons.child_care_rounded,
      ),
      CarSpecItem(
        key: 'anti_theft_alarm',
        labelAr: 'إنذار سرقة',
        labelEn: 'Anti-theft Alarm',
        type: CarSpecType.toggle,
        icon: Icons.notifications_active_rounded,
      ),
      CarSpecItem(
        key: 'central_locking',
        labelAr: 'إغلاق مركزي',
        labelEn: 'Central Locking',
        type: CarSpecType.toggle,
        icon: Icons.lock_rounded,
      ),
      CarSpecItem(
        key: 'child_lock',
        labelAr: 'قفل أطفال',
        labelEn: 'Child Lock',
        type: CarSpecType.toggle,
        icon: Icons.child_friendly_rounded,
      ),
    ],
  ),
  CarSpecCategory(
    key: 'adas',
    labelAr: 'أنظمة السلامة المتقدمة',
    labelEn: 'Advanced Safety (ADAS)',
    icon: Icons.visibility_rounded,
    color: Color(0xFF1D9E75),
    items: [
      CarSpecItem(
        key: 'lane_keep_assist',
        labelAr: 'متابعة المسار',
        labelEn: 'Lane Keep Assist',
        type: CarSpecType.toggle,
        icon: Icons.merge_rounded,
      ),
      CarSpecItem(
        key: 'auto_emergency_braking',
        labelAr: 'الفرامل التلقائية الطارئة',
        labelEn: 'Auto Emergency Braking',
        type: CarSpecType.toggle,
        icon: Icons.warning_amber_rounded,
      ),
      CarSpecItem(
        key: 'adaptive_cruise_control',
        labelAr: 'تثبيت السرعة التكيفي',
        labelEn: 'Adaptive Cruise Control',
        type: CarSpecType.toggle,
        icon: Icons.speed_rounded,
      ),
      CarSpecItem(
        key: 'camera_360',
        labelAr: 'كاميرا 360 درجة',
        labelEn: '360° Camera',
        type: CarSpecType.toggle,
        icon: Icons.camera_alt_rounded,
      ),
      CarSpecItem(
        key: 'camera_front',
        labelAr: 'كاميرا أمامية',
        labelEn: 'Front Camera',
        type: CarSpecType.toggle,
        icon: Icons.camera_front_rounded,
      ),
      CarSpecItem(
        key: 'camera_rear',
        labelAr: 'كاميرا خلفية',
        labelEn: 'Rear Camera',
        type: CarSpecType.toggle,
        icon: Icons.camera_rear_rounded,
      ),
      CarSpecItem(
        key: 'parking_sensors_front',
        labelAr: 'حساسات ركن أمامية',
        labelEn: 'Front Parking Sensors',
        type: CarSpecType.toggle,
        icon: Icons.sensors_rounded,
      ),
      CarSpecItem(
        key: 'parking_sensors_rear',
        labelAr: 'حساسات ركن خلفية',
        labelEn: 'Rear Parking Sensors',
        type: CarSpecType.toggle,
        icon: Icons.sensors_rounded,
      ),
      CarSpecItem(
        key: 'lane_departure_warning',
        labelAr: 'تنبيه مغادرة المسار',
        labelEn: 'Lane Departure Warning',
        type: CarSpecType.toggle,
        icon: Icons.warning_rounded,
      ),
      CarSpecItem(
        key: 'blind_spot_warning',
        labelAr: 'تحذير النقطة العمياء',
        labelEn: 'Blind Spot Warning',
        type: CarSpecType.toggle,
        icon: Icons.visibility_off_rounded,
      ),
      CarSpecItem(
        key: 'parking_assist',
        labelAr: 'مساعد صف السيارات',
        labelEn: 'Parking Assist',
        type: CarSpecType.toggle,
        icon: Icons.local_parking_rounded,
      ),
      CarSpecItem(
        key: 'forward_collision_warning',
        labelAr: 'تحذير الاصطدام الأمامي',
        labelEn: 'Forward Collision Warning',
        type: CarSpecType.toggle,
        icon: Icons.report_problem_rounded,
      ),
      CarSpecItem(
        key: 'driver_monitoring',
        labelAr: 'مراقبة سائق (كشف النعاس)',
        labelEn: 'Driver Monitoring',
        type: CarSpecType.toggle,
        icon: Icons.remove_red_eye_rounded,
      ),
      CarSpecItem(
        key: 'auto_high_beam',
        labelAr: 'مساعد الإضاءة العالية التلقائي',
        labelEn: 'Auto High Beam Assist',
        type: CarSpecType.toggle,
        icon: Icons.highlight_rounded,
      ),
      CarSpecItem(
        key: 'rear_cross_traffic_alert',
        labelAr: 'تنبيه حركة المرور الخلفية',
        labelEn: 'Rear Cross Traffic Alert',
        type: CarSpecType.toggle,
        icon: Icons.compare_arrows_rounded,
      ),
      CarSpecItem(
        key: 'hill_descent_ascent_assist',
        labelAr: 'مساعد صعود/نزول المرتفعات',
        labelEn: 'Hill Descent/Ascent Assist',
        type: CarSpecType.toggle,
        icon: Icons.terrain_rounded,
      ),
      CarSpecItem(
        key: 'head_up_display',
        labelAr: 'Head-Up Display',
        labelEn: 'Head-Up Display',
        type: CarSpecType.toggle,
        icon: Icons.airplanemode_active_rounded,
      ),
    ],
  ),
  CarSpecCategory(
    key: 'comfort',
    labelAr: 'الراحة الداخلية',
    labelEn: 'Interior Comfort',
    icon: Icons.weekend_rounded,
    color: Color(0xFFD4537E),
    items: [
      CarSpecItem(
        key: 'seats',
        labelAr: 'عدد المقاعد',
        labelEn: 'Seats',
        type: CarSpecType.choice,
        icon: Icons.event_seat_rounded,
        storesInColumn: 'seats',
        options: [
          CarSpecOption(value: '2', labelAr: '2', labelEn: '2'),
          CarSpecOption(value: '4', labelAr: '4', labelEn: '4'),
          CarSpecOption(value: '5', labelAr: '5', labelEn: '5'),
          CarSpecOption(value: '7', labelAr: '7', labelEn: '7'),
          CarSpecOption(value: '8', labelAr: '8', labelEn: '8'),
        ],
      ),
      CarSpecItem(
        key: 'seats_material',
        labelAr: 'نوع المقاعد',
        labelEn: 'Seats Material',
        type: CarSpecType.choice,
        icon: Icons.event_seat_rounded,
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
        icon: Icons.thermostat_rounded,
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
        icon: Icons.settings_input_component_rounded,
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
    icon: Icons.tv_rounded,
    color: Color(0xFFD85A30),
    items: [
      CarSpecItem(
        key: 'wireless_charger',
        labelAr: 'شاحن لاسلكي',
        labelEn: 'Wireless Charger',
        type: CarSpecType.toggle,
        icon: Icons.battery_charging_full_rounded,
        storesInColumn: 'wireless_charger',
      ),
      CarSpecItem(
        key: 'screen_size',
        labelAr: 'مقاس الشاشة',
        labelEn: 'Screen Size',
        type: CarSpecType.choice,
        icon: Icons.tv_rounded,
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
        icon: Icons.phone_iphone_rounded,
      ),
      CarSpecItem(
        key: 'android_auto',
        labelAr: 'Android Auto',
        labelEn: 'Android Auto',
        type: CarSpecType.toggle,
        icon: Icons.android_rounded,
      ),
      CarSpecItem(
        key: 'sound_system',
        labelAr: 'النظام الصوتي',
        labelEn: 'Sound System',
        type: CarSpecType.choice,
        icon: Icons.speaker_rounded,
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
    icon: Icons.inventory_2_rounded,
    color: Color(0xFF5F5E5A),
    items: [
      CarSpecItem(
        key: 'power_trunk',
        labelAr: 'فتح الصندوق كهربائي',
        labelEn: 'Power Trunk',
        type: CarSpecType.toggle,
        icon: Icons.airline_seat_legroom_extra_rounded,
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
