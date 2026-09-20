import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/favorites_compare.dart';
import '../shared/repository.dart';
import '../shared/widgets.dart';
import '../models/car.dart';
import '../screens/car_details_page.dart';

// ============================================================
// COMPARISON PAGE (مع اختيار السيارات من المخزون مباشرة)
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

  Future<void> _openCarPicker() async {
    final searchCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final results = cars.where((c) {
              if (compareCarIds.value.contains(c.id)) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${c.brand} ${c.name} ${c.nameEn}'.toLowerCase();
              return haystack.contains(query);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Text(
                        isArabic ? 'اختار سيارة للمقارنة' : 'Pick a car to compare',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: isArabic ? 'دوّر باسم السيارة أو الماركة' : 'Search by car or brand',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: results.isEmpty
                            ? Center(
                                child: Text(
                                  isArabic ? 'مفيش نتائج' : 'No results',
                                  style: const TextStyle(color: Colors.black45),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: results.length,
                                itemBuilder: (context, i) {
                                  final car = results[i];
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: carImageAdaptive(
                                          car.image,
                                          fit: BoxFit.cover,
                                          showWatermark: false,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${car.brand} ${car.displayName(isArabic)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      car.price,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () {
                                      toggleCompare(car.id!);
                                      Navigator.of(context).pop();
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _addSlot() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: _openCarPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline_rounded, color: Colors.red, size: 28),
                const SizedBox(height: 6),
                Text(
                  isArabic ? 'إضافة سيارة' : 'Add a car',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
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

    final emptySlots = (3 - selectedCars.length).clamp(0, 3);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'مقارنة السيارات' : 'Compare Cars'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // صف اختيار السيارات (كروت موجودة + أماكن فاضية للإضافة)
              Row(
                children: [
                  const SizedBox(width: 130),
                  ...selectedCars.map((car) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    height: 90,
                                    width: double.infinity,
                                    child: carImageAdaptive(
                                      car.image,
                                      fit: BoxFit.cover,
                                      showWatermark: false,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: InkWell(
                                    onTap: () => setState(() {
                                      toggleCompare(car.id!);
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                  for (var i = 0; i < emptySlots; i++) _addSlot(),
                ],
              ),

              if (selectedCars.length < 2) ...[
                const SizedBox(height: 30),
                Text(
                  isArabic
                      ? 'اختار سيارتين على الأقل عشان تبدأ المقارنة'
                      : 'Pick at least 2 cars to start comparing',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ] else ...[
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
                          padding: const EdgeInsets.symmetric(horizontal: 6),
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
            ],
          ),
        ),
      ),
    );
  }
}
