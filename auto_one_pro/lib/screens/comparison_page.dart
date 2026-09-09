import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/favorites_compare.dart';
import '../shared/repository.dart';
import '../shared/widgets.dart';
import '../screens/car_details_page.dart';

// ============================================================
// COMPARISON PAGE
// ============================================================
class ComparisonPage extends StatefulWidget {
  final bool isArabic;

  const ComparisonPage({super.key, required this.isArabic});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}


class _ComparisonPageState extends State<ComparisonPage> {
  bool get isArabic => widget.isArabic;

  Widget _row(String label, List<String> values) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ...values.map((v) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 8),
                  child: Text(
                    v.isEmpty ? '—' : v,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCars = compareCarIds.value
        .map((id) => cars.where((c) => c.id == id))
        .where((iterable) => iterable.isNotEmpty)
        .map((iterable) => iterable.first)
        .toList();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'مقارنة السيارات' : 'Compare Cars'),
        ),
        body: selectedCars.length < 2
            ? Center(
                child: Text(
                  isArabic
                      ? 'اختاري سيارتين على الأقل للمقارنة'
                      : 'Select at least 2 cars to compare',
                  style: const TextStyle(color: Colors.black54),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // IMAGES + NAMES ROW
                    Row(
                      children: [
                        const SizedBox(width: 130),
                        ...selectedCars.map((car) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: SizedBox(
                                      height: 90,
                                      child: carImageAdaptive(
                                        car.image,
                                        fit: BoxFit.cover,
                                        showWatermark: false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${car.brand} ${car.displayName(isArabic)}',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _row(
                      isArabic ? 'السعر' : 'Price',
                      selectedCars.map((c) => c.price).toList(),
                    ),
                    _row(
                      isArabic ? 'السنة' : 'Year',
                      selectedCars.map((c) => c.year).toList(),
                    ),
                    _row(
                      isArabic ? 'المحرك' : 'Engine',
                      selectedCars.map((c) => c.engine).toList(),
                    ),
                    _row(
                      isArabic ? 'ناقل الحركة' : 'Transmission',
                      selectedCars.map((c) => c.transmission).toList(),
                    ),
                    _row(
                      isArabic ? 'الوقود' : 'Fuel',
                      selectedCars.map((c) => c.fuel).toList(),
                    ),
                    _row(
                      isArabic ? 'المقاعد' : 'Seats',
                      selectedCars.map((c) => c.seats).toList(),
                    ),
                    _row(
                      isArabic ? 'نظام الدفع' : 'Drive',
                      selectedCars.map((c) => c.drive).toList(),
                    ),
                    _row(
                      isArabic ? 'قوة المحرك' : 'Horsepower',
                      selectedCars.map((c) => c.horsepower).toList(),
                    ),
                    _row(
                      isArabic ? 'عدد الوسائد الهوائية' : 'Airbags',
                      selectedCars.map((c) => c.airbags).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(width: 130),
                        ...selectedCars.map((car) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    smoothRoute(
                                      CarDetailsPage(
                                        car: car,
                                        isArabic: isArabic,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  isArabic ? 'التفاصيل' : 'Details',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

