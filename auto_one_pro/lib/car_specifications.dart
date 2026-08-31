import 'package:flutter/material.dart';

// ============================================================
// SPECIFICATION DEFINITION
// ============================================================

class CarSpecDefinition {
  final String id;
  final String nameAr;
  final String nameEn;
  final String category;
  final IconData icon;
  final String? defaultValue;

  const CarSpecDefinition({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.icon,
    this.defaultValue,
  });
}

// ============================================================
// SPECIFICATION CATEGORY
// ============================================================

class CarSpecCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;

  const CarSpecCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
  });
}

// ============================================================
// CATEGORIES
// ============================================================

const List<CarSpecCategory> carSpecCategories = [
  CarSpecCategory(
    id: 'engine',
    nameAr: 'المحرك والأداء',
    nameEn: 'Engine & Performance',
    icon: Icons.speed_rounded,
  ),

  CarSpecCategory(
    id: 'transmission',
    nameAr: 'ناقل الحركة والدفع',
    nameEn: 'Transmission & Drivetrain',
    icon: Icons.settings_rounded,
  ),

  CarSpecCategory(
    id: 'safety',
    nameAr: 'السلامة',
    nameEn: 'Safety',
    icon: Icons.shield_rounded,
  ),

  CarSpecCategory(
    id: 'adas',
    nameAr: 'أنظمة مساعدة السائق',
    nameEn: 'ADAS',
    icon: Icons.smart_toy_rounded,
  ),

  CarSpecCategory(
    id: 'camera',
    nameAr: 'الكاميرات والحساسات',
    nameEn: 'Cameras & Sensors',
    icon: Icons.camera_alt_rounded,
  ),

  CarSpecCategory(
    id: 'technology',
    nameAr: 'الشاشات والتكنولوجيا',
    nameEn: 'Technology',
    icon: Icons.devices_rounded,
  ),

  CarSpecCategory(
    id: 'audio',
    nameAr: 'النظام الصوتي',
    nameEn: 'Audio',
    icon: Icons.volume_up_rounded,
  ),

  CarSpecCategory(
    id: 'wheels',
    nameAr: 'الجنوط والإطارات',
    nameEn: 'Wheels & Tires',
    icon: Icons.tire_repair_rounded,
  ),

  CarSpecCategory(
    id: 'lighting',
    nameAr: 'الإضاءة',
    nameEn: 'Lighting',
    icon: Icons.light_mode_rounded,
  ),

  CarSpecCategory(
    id: 'seats',
    nameAr: 'المقاعد',
    nameEn: 'Seats',
    icon: Icons.event_seat_rounded,
  ),

  CarSpecCategory(
    id: 'climate',
    nameAr: 'التكييف',
    nameEn: 'Climate',
    icon: Icons.ac_unit_rounded,
  ),

  CarSpecCategory(
    id: 'comfort',
    nameAr: 'الراحة والتجهيزات',
    nameEn: 'Comfort & Convenience',
    icon: Icons.airline_seat_recline_extra_rounded,
  ),

  CarSpecCategory(
    id: 'exterior',
    nameAr: 'التجهيزات الخارجية',
    nameEn: 'Exterior',
    icon: Icons.directions_car_rounded,
  ),

  CarSpecCategory(
    id: 'dimensions',
    nameAr: 'الأبعاد والسعات',
    nameEn: 'Dimensions & Capacity',
    icon: Icons.straighten_rounded,
  ),

  CarSpecCategory(
    id: 'electric',
    nameAr: 'السيارات الكهربائية',
    nameEn: 'Electric & Hybrid',
    icon: Icons.bolt_rounded,
  ),
];

// ============================================================
// SPECIFICATIONS LIBRARY
// ============================================================

const List<CarSpecDefinition> carSpecifications = [

  // ==========================================================
  // ENGINE & PERFORMANCE
  // ==========================================================

  CarSpecDefinition(
    id: 'engine_type',
    nameAr: 'نوع المحرك',
    nameEn: 'Engine Type',
    category: 'engine',
    icon: Icons.engineering_rounded,
  ),

  CarSpecDefinition(
    id: 'engine_capacity',
    nameAr: 'سعة المحرك',
    nameEn: 'Engine Displacement',
    category: 'engine',
    icon: Icons.local_gas_station_rounded,
  ),

  CarSpecDefinition(
    id: 'cylinders',
    nameAr: 'عدد الأسطوانات',
    nameEn: 'Cylinders',
    category: 'engine',
    icon: Icons.settings_input_component_rounded,
  ),

  CarSpecDefinition(
    id: 'turbo',
    nameAr: 'تيربو',
    nameEn: 'Turbocharger',
    category: 'engine',
    icon: Icons.flash_on_rounded,
  ),

  CarSpecDefinition(
    id: 'supercharger',
    nameAr: 'سوبر تشارج',
    nameEn: 'Supercharger',
    category: 'engine',
    icon: Icons.bolt_rounded,
  ),

  CarSpecDefinition(
    id: 'horsepower',
    nameAr: 'القوة الحصانية',
    nameEn: 'Horsepower',
    category: 'engine',
    icon: Icons.speed_rounded,
  ),

  CarSpecDefinition(
    id: 'torque',
    nameAr: 'عزم الدوران',
    nameEn: 'Torque',
    category: 'engine',
    icon: Icons.rotate_right_rounded,
  ),

  CarSpecDefinition(
    id: 'zero_to_hundred',
    nameAr: 'التسارع 0 - 100 كم/س',
    nameEn: '0-100 km/h',
    category: 'engine',
    icon: Icons.timer_rounded,
  ),

  CarSpecDefinition(
    id: 'top_speed',
    nameAr: 'السرعة القصوى',
    nameEn: 'Top Speed',
    category: 'engine',
    icon: Icons.speed_rounded,
  ),

  CarSpecDefinition(
    id: 'fuel_consumption',
    nameAr: 'استهلاك الوقود',
    nameEn: 'Fuel Consumption',
    category: 'engine',
    icon: Icons.local_gas_station_rounded,
  ),

  CarSpecDefinition(
    id: 'fuel_tank',
    nameAr: 'سعة خزان الوقود',
    nameEn: 'Fuel Tank Capacity',
    category: 'engine',
    icon: Icons.local_gas_station_rounded,
  ),

  // ==========================================================
  // TRANSMISSION & DRIVETRAIN
  // ==========================================================

  CarSpecDefinition(
    id: 'transmission_type',
    nameAr: 'نوع ناقل الحركة',
    nameEn: 'Transmission Type',
    category: 'transmission',
    icon: Icons.settings_rounded,
  ),

  CarSpecDefinition(
    id: 'transmission_gears',
    nameAr: 'عدد السرعات',
    nameEn: 'Number of Gears',
    category: 'transmission',
    icon: Icons.tune_rounded,
  ),

  CarSpecDefinition(
    id: 'drive_type',
    nameAr: 'نظام الدفع',
    nameEn: 'Drive Type',
    category: 'transmission',
    icon: Icons.directions_car_filled_rounded,
  ),

  CarSpecDefinition(
    id: 'awd',
    nameAr: 'دفع رباعي AWD',
    nameEn: 'AWD',
    category: 'transmission',
    icon: Icons.all_inclusive_rounded,
  ),

  CarSpecDefinition(
    id: 'four_wd',
    nameAr: 'دفع رباعي 4WD',
    nameEn: '4WD',
    category: 'transmission',
    icon: Icons.terrain_rounded,
  ),

  CarSpecDefinition(
    id: 'four_wd_low',
    nameAr: 'دفع منخفض 4L',
    nameEn: '4WD Low Range',
    category: 'transmission',
    icon: Icons.landscape_rounded,
  ),

  CarSpecDefinition(
    id: 'diff_lock',
    nameAr: 'قفل الدفرنس',
    nameEn: 'Differential Lock',
    category: 'transmission',
    icon: Icons.lock_rounded,
  ),

  // ==========================================================
  // SAFETY
  // ==========================================================

  CarSpecDefinition(
    id: 'abs',
    nameAr: 'نظام منع انغلاق المكابح ABS',
    nameEn: 'ABS',
    category: 'safety',
    icon: Icons.car_crash_rounded,
  ),

  CarSpecDefinition(
    id: 'ebd',
    nameAr: 'توزيع إلكتروني للفرامل EBD',
    nameEn: 'EBD',
    category: 'safety',
    icon: Icons.alt_route_rounded,
  ),

  CarSpecDefinition(
    id: 'esc',
    nameAr: 'الثبات الإلكتروني ESC',
    nameEn: 'Electronic Stability Control',
    category: 'safety',
    icon: Icons.shield_rounded,
  ),

  CarSpecDefinition(
    id: 'traction_control',
    nameAr: 'مانع الانزلاق TCS',
    nameEn: 'Traction Control',
    category: 'safety',
    icon: Icons.traffic_rounded,
  ),

  CarSpecDefinition(
    id: 'brake_assist',
    nameAr: 'مساعد الفرامل',
    nameEn: 'Brake Assist',
    category: 'safety',
    icon: Icons.warning_rounded,
  ),

  CarSpecDefinition(
    id: 'hill_start',
    nameAr: 'مساعد صعود المرتفعات',
    nameEn: 'Hill Start Assist',
    category: 'safety',
    icon: Icons.trending_up_rounded,
  ),

  CarSpecDefinition(
    id: 'hill_descent',
    nameAr: 'مساعد نزول المنحدرات',
    nameEn: 'Hill Descent Control',
    category: 'safety',
    icon: Icons.trending_down_rounded,
  ),

  CarSpecDefinition(
    id: 'tpms',
    nameAr: 'مراقبة ضغط الإطارات',
    nameEn: 'TPMS',
    category: 'safety',
    icon: Icons.tire_repair_rounded,
  ),

  CarSpecDefinition(
    id: 'isofix',
    nameAr: 'مثبت مقاعد الأطفال ISOFIX',
    nameEn: 'ISOFIX',
    category: 'safety',
    icon: Icons.child_friendly_rounded,
  ),

  CarSpecDefinition(
    id: 'front_airbags',
    nameAr: 'وسائد هوائية أمامية',
    nameEn: 'Front Airbags',
    category: 'safety',
    icon: Icons.airline_seat_recline_normal_rounded,
  ),

  CarSpecDefinition(
    id: 'side_airbags',
    nameAr: 'وسائد هوائية جانبية',
    nameEn: 'Side Airbags',
    category: 'safety',
    icon: Icons.airline_seat_recline_normal_rounded,
  ),

  CarSpecDefinition(
    id: 'curtain_airbags',
    nameAr: 'وسائد هوائية ستارية',
    nameEn: 'Curtain Airbags',
    category: 'safety',
    icon: Icons.airline_seat_recline_normal_rounded,
  ),

  // ==========================================================
  // ADAS
  // ==========================================================

  CarSpecDefinition(
    id: 'aeb',
    nameAr: 'فرملة الطوارئ التلقائية',
    nameEn: 'Automatic Emergency Braking',
    category: 'adas',
    icon: Icons.emergency_rounded,
  ),

  CarSpecDefinition(
    id: 'fcw',
    nameAr: 'تحذير الاصطدام الأمامي',
    nameEn: 'Forward Collision Warning',
    category: 'adas',
    icon: Icons.warning_amber_rounded,
  ),

  CarSpecDefinition(
    id: 'acc',
    nameAr: 'مثبت سرعة متكيف',
    nameEn: 'Adaptive Cruise Control',
    category: 'adas',
    icon: Icons.speed_rounded,
  ),

  CarSpecDefinition(
    id: 'ldw',
    nameAr: 'تحذير مغادرة المسار',
    nameEn: 'Lane Departure Warning',
    category: 'adas',
    icon: Icons.alt_route_rounded,
  ),

  CarSpecDefinition(
    id: 'lka',
    nameAr: 'المحافظة على المسار',
    nameEn: 'Lane Keep Assist',
    category: 'adas',
    icon: Icons.compare_arrows_rounded,
  ),

  CarSpecDefinition(
    id: 'bsm',
    nameAr: 'مراقبة النقطة العمياء',
    nameEn: 'Blind Spot Monitoring',
    category: 'adas',
    icon: Icons.visibility_off_rounded,
  ),

  CarSpecDefinition(
    id: 'rcta',
    nameAr: 'تنبيه حركة المرور الخلفية',
    nameEn: 'Rear Cross Traffic Alert',
    category: 'adas',
    icon: Icons.directions_car_rounded,
  ),

  CarSpecDefinition(
    id: 'traffic_sign',
    nameAr: 'التعرف على إشارات المرور',
    nameEn: 'Traffic Sign Recognition',
    category: 'adas',
    icon: Icons.traffic_rounded,
  ),

  CarSpecDefinition(
    id: 'driver_monitoring',
    nameAr: 'مراقبة السائق',
    nameEn: 'Driver Monitoring',
    category: 'adas',
    icon: Icons.person_search_rounded,
  ),

  CarSpecDefinition(
    id: 'auto_parking',
    nameAr: 'ركن تلقائي',
    nameEn: 'Automatic Parking',
    category: 'adas',
    icon: Icons.local_parking_rounded,
  ),

  // ==========================================================
  // CAMERAS & SENSORS
  // ==========================================================

  CarSpecDefinition(
    id: 'rear_camera',
    nameAr: 'كاميرا خلفية',
    nameEn: 'Rear Camera',
    category: 'camera',
    icon: Icons.camera_rear_rounded,
  ),

  CarSpecDefinition(
    id: 'front_camera',
    nameAr: 'كاميرا أمامية',
    nameEn: 'Front Camera',
    category: 'camera',
    icon: Icons.camera_alt_rounded,
  ),

  CarSpecDefinition(
    id: '360_camera',
    nameAr: 'كاميرا 360 درجة',
    nameEn: '360° Camera',
    category: 'camera',
    icon: Icons.threesixty_rounded,
  ),

  CarSpecDefinition(
    id: 'parking_sensors_front',
    nameAr: 'حساسات أمامية',
    nameEn: 'Front Parking Sensors',
    category: 'camera',
    icon: Icons.sensors_rounded,
  ),

  CarSpecDefinition(
    id: 'parking_sensors_rear',
    nameAr: 'حساسات خلفية',
    nameEn: 'Rear Parking Sensors',
    category: 'camera',
    icon: Icons.sensors_rounded,
  ),

  // ==========================================================
  // TECHNOLOGY
  // ==========================================================

  CarSpecDefinition(
    id: 'digital_cluster',
    nameAr: 'عدادات رقمية',
    nameEn: 'Digital Cluster',
    category: 'technology',
    icon: Icons.dashboard_rounded,
  ),

  CarSpecDefinition(
    id: 'head_up_display',
    nameAr: 'شاشة عرض أمامية HUD',
    nameEn: 'Head-Up Display',
    category: 'technology',
    icon: Icons.view_in_ar_rounded,
  ),

  CarSpecDefinition(
    id: 'central_screen',
    nameAr: 'الشاشة الوسطية',
    nameEn: 'Central Display',
    category: 'technology',
    icon: Icons.tablet_android_rounded,
  ),

  CarSpecDefinition(
    id: 'apple_carplay',
    nameAr: 'Apple CarPlay',
    nameEn: 'Apple CarPlay',
    category: 'technology',
    icon: Icons.phone_iphone_rounded,
  ),

  CarSpecDefinition(
    id: 'android_auto',
    nameAr: 'Android Auto',
    nameEn: 'Android Auto',
    category: 'technology',
    icon: Icons.android_rounded,
  ),

  CarSpecDefinition(
    id: 'wireless_carplay',
    nameAr: 'Apple CarPlay لاسلكي',
    nameEn: 'Wireless CarPlay',
    category: 'technology',
    icon: Icons.wifi_rounded,
  ),

  CarSpecDefinition(
    id: 'wireless_charging',
    nameAr: 'شحن لاسلكي',
    nameEn: 'Wireless Charging',
    category: 'technology',
    icon: Icons.battery_charging_full_rounded,
  ),

  CarSpecDefinition(
    id: 'usb_c',
    nameAr: 'منافذ USB-C',
    nameEn: 'USB-C',
    category: 'technology',
    icon: Icons.usb_rounded,
  ),

  CarSpecDefinition(
    id: 'bluetooth',
    nameAr: 'Bluetooth',
    nameEn: 'Bluetooth',
    category: 'technology',
    icon: Icons.bluetooth_rounded,
  ),

  CarSpecDefinition(
    id: 'navigation',
    nameAr: 'نظام ملاحة',
    nameEn: 'Navigation',
    category: 'technology',
    icon: Icons.navigation_rounded,
  ),

  // ==========================================================
  // AUDIO
  // ==========================================================

  CarSpecDefinition(
    id: 'speakers',
    nameAr: 'عدد السماعات',
    nameEn: 'Number of Speakers',
    category: 'audio',
    icon: Icons.speaker_rounded,
  ),

  CarSpecDefinition(
    id: 'premium_audio',
    nameAr: 'نظام صوتي فاخر',
    nameEn: 'Premium Audio',
    category: 'audio',
    icon: Icons.graphic_eq_rounded,
  ),

  CarSpecDefinition(
    id: 'subwoofer',
    nameAr: 'Subwoofer',
    nameEn: 'Subwoofer',
    category: 'audio',
    icon: Icons.speaker_group_rounded,
  ),

  // ==========================================================
  // WHEELS & TIRES
  // ==========================================================

  CarSpecDefinition(
    id: 'wheel_size',
    nameAr: 'مقاس الجنوط',
    nameEn: 'Wheel Size',
    category: 'wheels',
    icon: Icons.tire_repair_rounded,
  ),

  CarSpecDefinition(
    id: 'alloy_wheels',
    nameAr: 'جنوط ألمنيوم',
    nameEn: 'Alloy Wheels',
    category: 'wheels',
    icon: Icons.album_rounded,
  ),

  CarSpecDefinition(
    id: 'spare_tire',
    nameAr: 'إطار احتياطي',
    nameEn: 'Spare Tire',
    category: 'wheels',
    icon: Icons.tire_repair_rounded,
  ),

  CarSpecDefinition(
    id: 'run_flat',
    nameAr: 'إطارات Run-Flat',
    nameEn: 'Run-Flat Tires',
    category: 'wheels',
    icon: Icons.tire_repair_rounded,
  ),

  // ==========================================================
  // LIGHTING
  // ==========================================================

  CarSpecDefinition(
    id: 'led_headlights',
    nameAr: 'مصابيح LED',
    nameEn: 'LED Headlights',
    category: 'lighting',
    icon: Icons.lightbulb_rounded,
  ),

  CarSpecDefinition(
    id: 'matrix_led',
    nameAr: 'Matrix LED',
    nameEn: 'Matrix LED',
    category: 'lighting',
    icon: Icons.highlight_rounded,
  ),

  CarSpecDefinition(
    id: 'daytime_running_lights',
    nameAr: 'إضاءة نهارية DRL',
    nameEn: 'Daytime Running Lights',
    category: 'lighting',
    icon: Icons.wb_sunny_rounded,
  ),

  CarSpecDefinition(
    id: 'auto_high_beam',
    nameAr: 'إضاءة عالية تلقائية',
    nameEn: 'Automatic High Beam',
    category: 'lighting',
    icon: Icons.flashlight_on_rounded,
  ),

  CarSpecDefinition(
    id: 'ambient_lighting',
    nameAr: 'إضاءة داخلية محيطية',
    nameEn: 'Ambient Lighting',
    category: 'lighting',
    icon: Icons.light_mode_rounded,
  ),

  // ==========================================================
  // SEATS
  // ==========================================================

  CarSpecDefinition(
    id: 'seat_material',
    nameAr: 'خامة المقاعد',
    nameEn: 'Seat Material',
    category: 'seats',
    icon: Icons.event_seat_rounded,
  ),

  CarSpecDefinition(
    id: 'power_seat',
    nameAr: 'مقاعد كهربائية',
    nameEn: 'Power Seats',
    category: 'seats',
    icon: Icons.electric_car_rounded,
  ),

  CarSpecDefinition(
    id: 'memory_seat',
    nameAr: 'ذاكرة المقاعد',
    nameEn: 'Memory Seats',
    category: 'seats',
    icon: Icons.memory_rounded,
  ),

  CarSpecDefinition(
    id: 'heated_seats',
    nameAr: 'تدفئة المقاعد',
    nameEn: 'Heated Seats',
    category: 'seats',
    icon: Icons.whatshot_rounded,
  ),

  CarSpecDefinition(
    id: 'ventilated_seats',
    nameAr: 'تهوية المقاعد',
    nameEn: 'Ventilated Seats',
    category: 'seats',
    icon: Icons.air_rounded,
  ),

  CarSpecDefinition(
    id: 'massage_seats',
    nameAr: 'مقاعد مع مساج',
    nameEn: 'Massage Seats',
    category: 'seats',
    icon: Icons.spa_rounded,
  ),

  // ==========================================================
  // CLIMATE
  // ==========================================================

  CarSpecDefinition(
    id: 'automatic_ac',
    nameAr: 'تكييف أوتوماتيكي',
    nameEn: 'Automatic Climate Control',
    category: 'climate',
    icon: Icons.ac_unit_rounded,
  ),

  CarSpecDefinition(
    id: 'dual_zone_ac',
    nameAr: 'تكييف ثنائي المناطق',
    nameEn: 'Dual Zone Climate',
    category: 'climate',
    icon: Icons.device_thermostat_rounded,
  ),

  CarSpecDefinition(
    id: 'tri_zone_ac',
    nameAr: 'تكييف ثلاثي المناطق',
    nameEn: 'Tri-Zone Climate',
    category: 'climate',
    icon: Icons.device_thermostat_rounded,
  ),

  CarSpecDefinition(
    id: 'rear_ac',
    nameAr: 'تكييف خلفي',
    nameEn: 'Rear AC',
    category: 'climate',
    icon: Icons.air_rounded,
  ),

  CarSpecDefinition(
    id: 'air_purification',
    nameAr: 'تنقية الهواء',
    nameEn: 'Air Purification',
    category: 'climate',
    icon: Icons.air_rounded,
  ),

  // ==========================================================
  // COMFORT
  // ==========================================================

  CarSpecDefinition(
    id: 'smart_key',
    nameAr: 'مفتاح ذكي',
    nameEn: 'Smart Key',
    category: 'comfort',
    icon: Icons.key_rounded,
  ),

  CarSpecDefinition(
    id: 'push_start',
    nameAr: 'تشغيل بصمة / زر',
    nameEn: 'Push Start',
    category: 'comfort',
    icon: Icons.power_settings_new_rounded,
  ),

  CarSpecDefinition(
    id: 'remote_start',
    nameAr: 'تشغيل عن بعد',
    nameEn: 'Remote Start',
    category: 'comfort',
    icon: Icons.settings_remote_rounded,
  ),

  CarSpecDefinition(
    id: 'auto_hold',
    nameAr: 'Auto Hold',
    nameEn: 'Auto Hold',
    category: 'comfort',
    icon: Icons.pan_tool_rounded,
  ),

  CarSpecDefinition(
    id: 'electric_parking_brake',
    nameAr: 'فرامل يد كهربائية',
    nameEn: 'Electric Parking Brake',
    category: 'comfort',
    icon: Icons.local_parking_rounded,
  ),

  CarSpecDefinition(
    id: 'power_windows',
    nameAr: 'نوافذ كهربائية',
    nameEn: 'Power Windows',
    category: 'comfort',
    icon: Icons.window_rounded,
  ),

  CarSpecDefinition(
    id: 'power_tailgate',
    nameAr: 'باب شنطة كهربائي',
    nameEn: 'Power Tailgate',
    category: 'comfort',
    icon: Icons.luggage_rounded,
  ),

  CarSpecDefinition(
    id: 'hands_free_tailgate',
    nameAr: 'فتح الشنطة بدون استخدام اليد',
    nameEn: 'Hands-Free Tailgate',
    category: 'comfort',
    icon: Icons.sensor_door_rounded,
  ),

  CarSpecDefinition(
    id: 'rain_sensor',
    nameAr: 'حساس مطر',
    nameEn: 'Rain Sensor',
    category: 'comfort',
    icon: Icons.water_drop_rounded,
  ),

  CarSpecDefinition(
    id: 'auto_dimming_mirror',
    nameAr: 'مرآة تعتيم تلقائي',
    nameEn: 'Auto Dimming Mirror',
    category: 'comfort',
    icon: Icons.flip_rounded,
  ),

  // ==========================================================
  // EXTERIOR
  // ==========================================================

  CarSpecDefinition(
    id: 'sunroof',
    nameAr: 'فتحة سقف',
    nameEn: 'Sunroof',
    category: 'exterior',
    icon: Icons.wb_sunny_rounded,
  ),

  CarSpecDefinition(
    id: 'panoramic_roof',
    nameAr: 'سقف بانوراما',
    nameEn: 'Panoramic Roof',
    category: 'exterior',
    icon: Icons.panorama_rounded,
  ),

  CarSpecDefinition(
    id: 'roof_rails',
    nameAr: 'قضبان سقف',
    nameEn: 'Roof Rails',
    category: 'exterior',
    icon: Icons.linear_scale_rounded,
  ),

  CarSpecDefinition(
    id: 'power_mirrors',
    nameAr: 'مرايا كهربائية',
    nameEn: 'Power Mirrors',
    category: 'exterior',
    icon: Icons.view_sidebar_rounded,
  ),

  CarSpecDefinition(
    id: 'heated_mirrors',
    nameAr: 'مرايا مدفأة',
    nameEn: 'Heated Mirrors',
    category: 'exterior',
    icon: Icons.whatshot_rounded,
  ),

  CarSpecDefinition(
    id: 'folding_mirrors',
    nameAr: 'مرايا قابلة للطي',
    nameEn: 'Folding Mirrors',
    category: 'exterior',
    icon: Icons.unfold_less_rounded,
  ),

  CarSpecDefinition(
    id: 'tow_hitch',
    nameAr: 'وصلة سحب',
    nameEn: 'Tow Hitch',
    category: 'exterior',
    icon: Icons.link_rounded,
  ),

  // ==========================================================
  // DIMENSIONS & CAPACITY
  // ==========================================================

  CarSpecDefinition(
    id: 'length',
    nameAr: 'الطول',
    nameEn: 'Length',
    category: 'dimensions',
    icon: Icons.straighten_rounded,
  ),

  CarSpecDefinition(
    id: 'width',
    nameAr: 'العرض',
    nameEn: 'Width',
    category: 'dimensions',
    icon: Icons.swap_horiz_rounded,
  ),

  CarSpecDefinition(
    id: 'height',
    nameAr: 'الارتفاع',
    nameEn: 'Height',
    category: 'dimensions',
    icon: Icons.height_rounded,
  ),

  CarSpecDefinition(
    id: 'wheelbase',
    nameAr: 'قاعدة العجلات',
    nameEn: 'Wheelbase',
    category: 'dimensions',
    icon: Icons.straighten_rounded,
  ),

  CarSpecDefinition(
    id: 'ground_clearance',
    nameAr: 'الخلوص الأرضي',
    nameEn: 'Ground Clearance',
    category: 'dimensions',
    icon: Icons.height_rounded,
  ),

  CarSpecDefinition(
    id: 'trunk_capacity',
    nameAr: 'سعة صندوق الأمتعة',
    nameEn: 'Cargo Capacity',
    category: 'dimensions',
    icon: Icons.luggage_rounded,
  ),

  CarSpecDefinition(
    id: 'seat_count',
    nameAr: 'عدد المقاعد',
    nameEn: 'Seat Count',
    category: 'dimensions',
    icon: Icons.event_seat_rounded,
  ),

  // ==========================================================
  // ELECTRIC & HYBRID
  // ==========================================================

  CarSpecDefinition(
    id: 'hybrid',
    nameAr: 'هايبرد',
    nameEn: 'Hybrid',
    category: 'electric',
    icon: Icons.eco_rounded,
  ),

  CarSpecDefinition(
    id: 'plug_in_hybrid',
    nameAr: 'هايبرد قابل للشحن',
    nameEn: 'Plug-in Hybrid',
    category: 'electric',
    icon: Icons.ev_station_rounded,
  ),

  CarSpecDefinition(
    id: 'ev',
    nameAr: 'سيارة كهربائية',
    nameEn: 'Electric Vehicle',
    category: 'electric',
    icon: Icons.electric_car_rounded,
  ),

  CarSpecDefinition(
    id: 'battery_capacity',
    nameAr: 'سعة البطارية',
    nameEn: 'Battery Capacity',
    category: 'electric',
    icon: Icons.battery_full_rounded,
  ),

  CarSpecDefinition(
    id: 'electric_range',
    nameAr: 'المدى الكهربائي',
    nameEn: 'Electric Range',
    category: 'electric',
    icon: Icons.route_rounded,
  ),

  CarSpecDefinition(
    id: 'ac_charging',
    nameAr: 'الشحن AC',
    nameEn: 'AC Charging',
    category: 'electric',
    icon: Icons.ev_station_rounded,
  ),

  CarSpecDefinition(
    id: 'dc_fast_charging',
    nameAr: 'الشحن السريع DC',
    nameEn: 'DC Fast Charging',
    category: 'electric',
    icon: Icons.bolt_rounded,
  ),

  CarSpecDefinition(
    id: 'charging_time',
    nameAr: 'وقت الشحن',
    nameEn: 'Charging Time',
    category: 'electric',
    icon: Icons.timer_rounded,
  ),

  CarSpecDefinition(
    id: 'regenerative_braking',
    nameAr: 'استعادة الطاقة عند الفرملة',
    nameEn: 'Regenerative Braking',
    category: 'electric',
    icon: Icons.energy_savings_leaf_rounded,
  ),

  CarSpecDefinition(
    id: 'v2l',
    nameAr: 'تغذية الأجهزة V2L',
    nameEn: 'Vehicle-to-Load',
    category: 'electric',
    icon: Icons.power_rounded,
  ),
];