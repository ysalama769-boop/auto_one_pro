import 'package:flutter/material.dart';

class CarColor {
  final String id;
  final String nameAr;
  final String nameEn;
  final Color color;

  const CarColor({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.color,
  });
}

class CarColorLibrary {
  static const List<CarColor> all = [
    CarColor(
      id: 'white',
      nameAr: 'أبيض',
      nameEn: 'White',
      color: Colors.white,
    ),

    CarColor(
      id: 'pearl_white',
      nameAr: 'أبيض لؤلؤي',
      nameEn: 'Pearl White',
      color: Color(0xFFF5F5F0),
    ),

    CarColor(
      id: 'black',
      nameAr: 'أسود',
      nameEn: 'Black',
      color: Colors.black,
    ),

    CarColor(
      id: 'pearl_black',
      nameAr: 'أسود لؤلؤي',
      nameEn: 'Pearl Black',
      color: Color(0xFF151515),
    ),

    CarColor(
      id: 'silver',
      nameAr: 'فضي',
      nameEn: 'Silver',
      color: Color(0xFFC0C0C0),
    ),

    CarColor(
      id: 'gray',
      nameAr: 'رمادي',
      nameEn: 'Gray',
      color: Color(0xFF808080),
    ),

    CarColor(
      id: 'dark_gray',
      nameAr: 'رمادي غامق',
      nameEn: 'Dark Gray',
      color: Color(0xFF444444),
    ),

    CarColor(
      id: 'blue',
      nameAr: 'أزرق',
      nameEn: 'Blue',
      color: Colors.blue,
    ),

    CarColor(
      id: 'navy_blue',
      nameAr: 'كحلي',
      nameEn: 'Navy Blue',
      color: Color(0xFF0B1F3A),
    ),

    CarColor(
      id: 'red',
      nameAr: 'أحمر',
      nameEn: 'Red',
      color: Colors.red,
    ),

    CarColor(
      id: 'dark_red',
      nameAr: 'أحمر غامق',
      nameEn: 'Dark Red',
      color: Color(0xFF8B0000),
    ),

    CarColor(
      id: 'burgundy',
      nameAr: 'نبيتي',
      nameEn: 'Burgundy',
      color: Color(0xFF800020),
    ),

    CarColor(
      id: 'brown',
      nameAr: 'بني',
      nameEn: 'Brown',
      color: Colors.brown,
    ),

    CarColor(
      id: 'beige',
      nameAr: 'بيج',
      nameEn: 'Beige',
      color: Color(0xFFD8C3A5),
    ),

    CarColor(
      id: 'gold',
      nameAr: 'ذهبي',
      nameEn: 'Gold',
      color: Color(0xFFD4AF37),
    ),

    CarColor(
      id: 'green',
      nameAr: 'أخضر',
      nameEn: 'Green',
      color: Colors.green,
    ),

    CarColor(
      id: 'dark_green',
      nameAr: 'أخضر غامق',
      nameEn: 'Dark Green',
      color: Color(0xFF1B5E20),
    ),

    CarColor(
      id: 'orange',
      nameAr: 'برتقالي',
      nameEn: 'Orange',
      color: Colors.orange,
    ),

    CarColor(
      id: 'yellow',
      nameAr: 'أصفر',
      nameEn: 'Yellow',
      color: Colors.yellow,
    ),

    CarColor(
      id: 'bronze',
      nameAr: 'برونزي',
      nameEn: 'Bronze',
      color: Color(0xFFCD7F32),
    ),
  ];

  static CarColor? getById(String id) {
    try {
      return all.firstWhere((color) => color.id == id);
    } catch (_) {
      return null;
    }
  }
}