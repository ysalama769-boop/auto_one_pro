import 'dart:async';
import 'package:flutter/material.dart';
import '../models/car.dart';
import '../shared/repository.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../screens/home_page.dart';
import '../admin/admin_shared.dart';

// ============================================================
// CARS PAGE
// ============================================================

class CarsPage extends StatefulWidget {
  final bool isArabic;
  final String? initialBrand;
  final bool initialOffers;
  final String? initialBodyType;

  const CarsPage({
    super.key,
    required this.isArabic,
    this.initialBrand,
    this.initialOffers = false,
    this.initialBodyType,
  });

  @override
  State<CarsPage> createState() => _CarsPageState();
}


class _CarsPageState extends State<CarsPage> {
  String search = '';
  bool showOffers = false;
  bool _isLoadingMoreCars = false;

 String selectedBrand = 'ALL';

@override
void initState() {
  super.initState();

  selectedBrand = widget.initialBrand ?? 'ALL';
  showOffers = widget.initialOffers;
  selectedBodyType = widget.initialBodyType ?? 'ALL';

  _loadRemainingCarsInBackground();
}

// بنكمّل تحميل باقي السيارات (20 سيارة كل مرة) في الخلفية، بدل
// ما نستنّى كل السيارات تتحمّل الأول قبل ما الصفحة تبان — الزائر
// بيشوف أول دفعة على طول، والباقي بيكمل يتحمّل وهو بيتصفّح.
Future<void> _loadRemainingCarsInBackground() async {
  if (!hasMoreCarsToLoad || _isLoadingMoreCars) return;

  setState(() => _isLoadingMoreCars = true);

  while (hasMoreCarsToLoad) {
    final gotMore = await loadMoreCars();
    if (!mounted) return;
    if (gotMore) setState(() {});
    if (!gotMore) break;
  }

  if (mounted) setState(() => _isLoadingMoreCars = false);
}
  String selectedType = 'ALL';
  String selectedCategory = 'ALL';
  String selectedModel = 'ALL';
  // نوع الجسم (SUV / سيدان / جيب) — فلتر منفصل عن باقي الفلاتر
  String selectedBodyType = 'ALL';
  // اسم الماركة المفتوحة حاليًا في عمود الماركات الجانبي (بتوري
  // الأنواع تحتها)، أو null لو مفيش ماركة مفتوحة
  String? expandedSidebarBrand;
  // اسم الموديل المختار من عمود الماركات الجانبي (زي "إلنترا")
  String selectedCarName = 'ALL';
  // بيتفعّل على الموبايل بس، لما تدوسي على زرار الماركات فيفتح
  // قائمة الماركات كـ Drawer منزلق من جنب الشاشة
  bool showMobileFilterDrawer = false;

  // فلترة السعر والترتيب
  double? minPrice;
  double? maxPrice;
  String sortOption = 'newest'; // newest, price_asc, price_desc

  // عرض السيارات على دفعات (25 في كل مرة) بدل ما نعرضهم كلهم مرة
  // واحدة، وده بيسرّع فتح الصفحة لما يكون عدد السيارات كبير.
  static const int _carsPerPage = 20;
  int _visibleCarsCount = _carsPerPage;
  String _lastFilterSignature = '';

  final TextEditingController controller =
      TextEditingController();

  // ============================================================
  // NORMALIZE SEARCH
  // ============================================================

  String _normalize(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _searchAlias(Car car) {
  final text = _normalize(
    [
      car.name,
      car.nameEn,
      car.brand,
      car.category,
      car.year,
      car.description,
      car.descriptionEn,
      _carType(car),
      _carCategory(car),
    ].join(' '),
  );

  final aliases = <String>[
    'جيتور jetour',
    'g700 جي 700',
    'x70 اكس 70',
    'x50 اكس 50',
    't1 تي 1',
    't2 تي 2',
    'dashing داشينج',

    'كيا kia',
    'سونيت sonet',
    'سيلتوس seltos',
    'سورينتو sorento',
    'كرنفال carnival',
    'تيلورايد telluride',

    'هيونداي hyundai',
    'توسان tucson',
    'كريتا creta',
    'كونا kona',
    'النترا elantra',
    'اكسنت accent',
    'سوناتا sonata',

    'نيسان nissan',
    'باترول patrol',
    'اكستريل xtrail x-trail',
    'التيما altima',
    'ماجنيت magnite',

    'فورد ford',
    'اكسبلور explorer',
    'تيريتوري territory',
    'تورس taurus',

    'بايك baic',
    'byd بي واي دي',
    'mg ام جي',
    'شيري chery',
    'gac جى اي سي',
    'تويوتا toyota',

    'كمفورت comfort',
    'لاكشري luxury lux',
    'بريميوم premium',
    'فلاجشيب flagship',
    'سمارت smart',
    'ستاندر standard',
    'استاندر standard',
  ];

  return '$text ${aliases.join(' ')}';
}
  // ============================================================
  // TYPE / FAMILY
  // ============================================================

  String _carType(Car car) {
    final name = _normalize(car.name);

    // JETOUR
    if (name.contains('g700')) return 'G700';
    if (name.contains('t2')) return 'T2';
    if (name.contains('t1')) return 'T1';
    if (name.contains('x70')) return 'X70';
    if (name.contains('x50')) return 'X50';
    if (name.contains('dashing')) return 'DASHING';

    // KIA
    if (name.contains('telluride') ||
        name.contains('تيلورايد')) {
      return 'TELLURIDE';
    }

    if (name.contains('carnival') ||
        name.contains('كرنفال')) {
      return 'CARNIVAL';
    }

    if (name.contains('sorento') ||
        name.contains('سورينتو')) {
      return 'SORENTO';
    }

    if (name.contains('carens') ||
        name.contains('كارينز')) {
      return 'CARENS';
    }

    if (name.contains('seltos') ||
        name.contains('سيلتوس')) {
      return 'SELTOS';
    }

    if (name.contains('sonet')) {
      return 'SONET';
    }

    if (name.contains('k8')) return 'K8';
    if (name.contains('k5')) return 'K5';
    if (name.contains('k4')) return 'K4';
    if (name.contains('k3')) return 'K3';

    if (name.contains('pegas') ||
        name.contains('بيجاس')) {
      return 'PEGAS';
    }

    // HYUNDAI
    if (name.contains('sonata') ||
        name.contains('سوناتا')) {
      return 'SONATA';
    }

    if (name.contains('tucson') ||
        name.contains('توسان')) {
      return 'TUCSON';
    }

    if (name.contains('creta') ||
        name.contains('كريتا')) {
      return 'CRETA';
    }

    if (name.contains('kona') ||
        name.contains('كونا')) {
      return 'KONA';
    }

    if (name.contains('elantra') ||
        name.contains('النترا')) {
      return 'ELANTRA';
    }

    if (name.contains('accent') ||
        name.contains('اكسنت')) {
      return 'ACCENT';
    }

    // NISSAN
    if (name.contains('patrol') ||
        name.contains('باترول')) {
      return 'PATROL';
    }

    if (name.contains('x-trail') ||
        name.contains('xtrail') ||
        name.contains('اكستريل')) {
      return 'X-TRAIL';
    }

    if (name.contains('altima') ||
        name.contains('التيما')) {
      return 'ALTIMA';
    }

    if (name.contains('magnite') ||
        name.contains('ماجنيت')) {
      return 'MAGNITE';
    }

    // FORD
    if (name.contains('explorer') ||
        name.contains('اكسبلور')) {
      return 'EXPLORER';
    }

    if (name.contains('territory') ||
        name.contains('تيريتوري')) {
      return 'TERRITORY';
    }

    if (name.contains('taurus') ||
        name.contains('تورس')) {
      return 'TAURUS';
    }

    // BAIC
    if (name.contains('u5')) return 'U5';
    if (name.contains('x75')) return 'X75';
    if (name.contains('x55')) return 'X55';
    if (name.contains('x35')) return 'X35';

    // BYD
    if (name.contains('song plus') ||
        name.contains('song')) {
      return 'SONG PLUS';
    }

    // CHERY
    if (name.contains('tiggo 7') ||
        name.contains('تيجو 7')) {
      return 'TIGGO 7';
    }

    if (name.contains('tiggo 4') ||
        name.contains('تيجو 4')) {
      return 'TIGGO 4';
    }

    if (name.contains('tiggo 2') ||
        name.contains('تيجو 2')) {
      return 'TIGGO 2';
    }

    if (name.contains('arrizo') ||
        name.contains('اريزو')) {
      return 'ARRIZO 5';
    }

    // MG
    if (name.contains('mg zs') ||
        name.contains('mg zs')) {
      return 'MG ZS';
    }

    if (name.contains('mg 5')) {
      return 'MG 5';
    }

    // JAC / RELY / JAC / JELLY
    if (name.contains('rely')) return 'RELY';

    if (name.contains('empow') ||
        name.contains('امباو')) {
      return 'EMPOW';
    }

    if (name.contains('emzoom') ||
        name.contains('ام زوم')) {
      return 'EMZOOM';
    }

    if (name.contains('okavango') ||
        name.contains('كافانجو')) {
      return 'OKAVANGO';
    }

    if (name.contains('staria') ||
        name.contains('ستاريا')) {
      return 'STARIA';
    }

    // TOYOTA
    if (name.contains('corolla') ||
        name.contains('كورولا')) {
      return 'COROLLA';
    }

    if (name.contains('yaris') ||
        name.contains('يارس')) {
      return 'YARIS';
    }

    // fallback
    return car.brand;
  }

  // ============================================================
  // CATEGORY / TRIM
  // ============================================================

  String _carCategory(Car car) {
    final name = _normalize(car.name);

    if (name.contains('comfort') ||
        name.contains('كمفورت')) {
      return 'COMFORT';
    }

    if (name.contains('lux') ||
        name.contains('luxury') ||
        name.contains('لاكشري')) {
      return 'LUX';
    }

    if (name.contains('premium') ||
        name.contains('بريميوم')) {
      return 'PREMIUM';
    }

    if (name.contains('flagship') ||
        name.contains('فلاجشيب')) {
      return 'FLAGSHIP';
    }

    if (name.contains('smart') ||
        name.contains('سمارت')) {
      return 'SMART';
    }

    if (name.contains('titanium') ||
        name.contains('تيتانيوم')) {
      return 'TITANIUM';
    }

    if (name.contains('trend') ||
        name.contains('ترند')) {
      return 'TREND';
    }

    if (name.contains('gls')) {
      return 'GLS';
    }

    if (name.contains('gl')) {
      return 'GL';
    }

    if (name.contains('standard') ||
        name.contains('استاندر') ||
        name.contains('ستاندر')) {
      return 'STANDARD';
    }

    if (name.contains('comfort')) {
      return 'COMFORT';
    }

    if (name.contains('sv')) return 'SV';
    if (name.contains('se')) return 'SE';
    if (name.contains('xlt')) return 'XLT';
    if (name.contains('xls')) return 'XLS';

    return 'OTHER';
  }

  // ============================================================
  // BRAND LIST
  // ============================================================

  List<String> get inventoryBrands {
    final values = cars
        .map((car) => car.brand)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ['ALL', ...values];
  }

  // بترجع أسماء الموديلات المتاحة فعليًا لماركة معيّنة (زي
  // "إلنترا"، "توسان")، عشان عمود الماركات الجانبي يوريها.
  List<String> _modelsForBrand(String brand) {
    final values = cars
        .where((car) => car.brand == brand)
        .map((car) => car.name.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  // ============================================================
  // TYPE LIST
  // ============================================================

  List<String> get inventoryTypes {
    final values = cars
        .where(
          (car) =>
              selectedBrand == 'ALL' ||
              car.brand == selectedBrand,
        )
        .map(_carType)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ['ALL', ...values];
  }

  // ============================================================
  // CATEGORY LIST
  // ============================================================

  List<String> get inventoryCategories {
    final values = cars
        .where(
          (car) =>
              (selectedBrand == 'ALL' ||
                  car.brand == selectedBrand) &&
              (selectedType == 'ALL' ||
                  _carType(car) == selectedType),
        )
        .map(_carCategory)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ['ALL', ...values];
  }

  // ============================================================
  // MODEL / YEAR LIST
  // ============================================================

  List<String> get inventoryModels {
    final values = cars
        .where(
          (car) =>
              (selectedBrand == 'ALL' ||
                  car.brand == selectedBrand) &&
              (selectedType == 'ALL' ||
                  _carType(car) == selectedType) &&
              (selectedCategory == 'ALL' ||
                  _carCategory(car) == selectedCategory),
        )
        .map((car) => car.year)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ['ALL', ...values];
  }

  // ============================================================
  // SEARCH + FILTERED CARS
  // ============================================================

  // بتحول نص السعر (زي "65,285") لرقم قابل للمقارنة
  double _parsePrice(String price) {
    final digits = price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  List<Car> get filteredCars {
    final query = _normalize(search);

    final result = cars.where((car) {
      final searchableText = _searchAlias(car);

      final matchesSearch =
          query.isEmpty ||
          searchableText.contains(query);

      final matchesBrand =
          selectedBrand == 'ALL' ||
          car.brand == selectedBrand;

      final matchesType =
          selectedType == 'ALL' ||
          _carType(car) == selectedType;

      final matchesCategory =
          selectedCategory == 'ALL' ||
          _carCategory(car) == selectedCategory;

      final matchesModel =
          selectedModel == 'ALL' ||
          car.year == selectedModel;
          final matchesOffer =
    !showOffers || car.isOfferActive;

      final matchesBodyType =
          selectedBodyType == 'ALL' ||
          car.category.trim().toUpperCase() == selectedBodyType;

      final matchesCarName =
          selectedCarName == 'ALL' || car.name.trim() == selectedCarName;

      final price = _parsePrice(car.price);
      final matchesMinPrice = minPrice == null || price >= minPrice!;
      final matchesMaxPrice = maxPrice == null || price <= maxPrice!;

     return matchesSearch &&
    matchesBrand &&
    matchesType &&
    matchesCategory &&
    matchesModel &&
    matchesOffer &&
    matchesBodyType &&
    matchesCarName &&
    matchesMinPrice &&
    matchesMaxPrice;
    }).toList();

    switch (sortOption) {
      case 'price_asc':
        result.sort(
          (a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)),
        );
        break;
      case 'price_desc':
        result.sort(
          (a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)),
        );
        break;
      default:
        // الأحدث: نرتب حسب الـ id تنازليًا (الأحدث إضافة أولًا)
        result.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    }

    return result;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCHABLE SELECT
  // ============================================================

  Future<String?> _openSearchSelect({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String selectedValue,
  }) async {
    String query = '';

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final filteredItems = items.where((item) {
              if (item == 'ALL') return true;

              return _normalize(item).contains(
                _normalize(query),
              );
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    20,
              ),
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height * 900,
                child: Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      autofocus: true,
                      onChanged: (value) {
                        modalSetState(() {
                          query = value;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.search_rounded),
                        hintText: widget.isArabic
                            ? 'اكتب للبحث...'
                            : 'Type to search...',
                        filled: true,
                        fillColor:
                            const Color(0xfff6f6f6),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                widget.isArabic
                                    ? 'لا توجد نتائج مطابقة'
                                    : 'NO MATCHING RESULTS',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black54,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount:
                                  filteredItems.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const Divider(
                                height: 1,
                              ),
                              itemBuilder:
                                  (context, index) {
                                final item =
                                    filteredItems[index];

                                final displayValue =
                                    item == 'ALL'
                                        ? (widget.isArabic
                                            ? 'الكل'
                                            : 'ALL')
                                        : item;

                                return ListTile(
                                  title: Text(
                                    displayValue,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                  trailing:
                                      item == selectedValue
                                          ? const Icon(
                                              Icons
                                                  .check_circle,
                                              color: Colors.red,
                                            )
                                          : null,
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                      item,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FILTER SHEET
  // ============================================================

  void _showFilters(BuildContext context) {
    String tempBrand = selectedBrand;
    String tempType = selectedType;
    String tempCategory = selectedCategory;
    String tempModel = selectedModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            List<String> tempTypes = cars
                .where(
                  (car) =>
                      tempBrand == 'ALL' ||
                      car.brand == tempBrand,
                )
                .map(_carType)
                .toSet()
                .toList()
              ..sort();

            List<String> tempCategories = cars
                .where(
                  (car) =>
                      (tempBrand == 'ALL' ||
                          car.brand == tempBrand) &&
                      (tempType == 'ALL' ||
                          _carType(car) == tempType),
                )
                .map(_carCategory)
                .toSet()
                .toList()
              ..sort();

            List<String> tempModels = cars
                .where(
                  (car) =>
                      (tempBrand == 'ALL' ||
                          car.brand == tempBrand) &&
                      (tempType == 'ALL' ||
                          _carType(car) == tempType) &&
                      (tempCategory == 'ALL' ||
                          _carCategory(car) == tempCategory),
                )
                .map((car) => car.year)
                .toSet()
                .toList()
              ..sort();

            tempTypes = ['ALL', ...tempTypes];
            tempCategories = ['ALL', ...tempCategories];
            tempModels = ['ALL', ...tempModels];

            final canApply =
                tempBrand != 'ALL' &&
                tempType != 'ALL' &&
                tempCategory != 'ALL' &&
                tempModel != 'ALL';

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 10,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.isArabic
                          ? 'فلترة السيارات'
                          : 'FILTER CARS',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BRAND
                    InkWell(
                      onTap: () async {
                        final result =
                            await _openSearchSelect(
                          context: context,
                          title: widget.isArabic
                              ? 'الماركة'
                              : 'BRAND',
                          items: inventoryBrands,
                          selectedValue: tempBrand,
                        );

                        if (result == null) return;

                        modalSetState(() {
                          tempBrand = result;
                          tempType = 'ALL';
                          tempCategory = 'ALL';
                          tempModel = 'ALL';
                        });
                      },
                      borderRadius:
                          BorderRadius.circular(14),
                      child: _filterBox(
                        title: widget.isArabic
                            ? 'الماركة'
                            : 'BRAND',
                        value: tempBrand == 'ALL'
                            ? (widget.isArabic
                                ? 'اختر الماركة'
                                : 'SELECT BRAND')
                            : tempBrand,
                        enabled: true,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // TYPE
                    InkWell(
                      onTap: tempBrand == 'ALL'
                          ? null
                          : () async {
                              final result =
                                  await _openSearchSelect(
                                context: context,
                                title: widget.isArabic
                                    ? 'النوع'
                                    : 'TYPE',
                                items: tempTypes,
                                selectedValue: tempType,
                              );

                              if (result == null) return;

                              modalSetState(() {
                                tempType = result;
                                tempCategory = 'ALL';
                                tempModel = 'ALL';
                              });
                            },
                      borderRadius:
                          BorderRadius.circular(14),
                      child: _filterBox(
                        title: widget.isArabic
                            ? 'النوع'
                            : 'TYPE',
                        value: tempType == 'ALL'
                            ? (widget.isArabic
                                ? 'اختر النوع'
                                : 'SELECT TYPE')
                            : tempType,
                        enabled: tempBrand != 'ALL',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CATEGORY
                    InkWell(
                      onTap:
                          tempType == 'ALL'
                              ? null
                              : () async {
                                  final result =
                                      await _openSearchSelect(
                                    context: context,
                                    title: widget.isArabic
                                        ? 'الفئة'
                                        : 'CATEGORY',
                                    items:
                                        tempCategories,
                                    selectedValue:
                                        tempCategory,
                                  );

                                  if (result == null) return;

                                  modalSetState(() {
                                    tempCategory = result;
                                    tempModel = 'ALL';
                                  });
                                },
                      borderRadius:
                          BorderRadius.circular(14),
                      child: _filterBox(
                        title: widget.isArabic
                            ? 'الفئة'
                            : 'CATEGORY',
                        value: tempCategory == 'ALL'
                            ? (widget.isArabic
                                ? 'اختر الفئة'
                                : 'SELECT CATEGORY')
                            : tempCategory,
                        enabled: tempType != 'ALL',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // MODEL / YEAR
                    InkWell(
                      onTap:
                          tempCategory == 'ALL'
                              ? null
                              : () async {
                                  final result =
                                      await _openSearchSelect(
                                    context: context,
                                    title: widget.isArabic
                                        ? 'الموديل'
                                        : 'MODEL',
                                    items: tempModels,
                                    selectedValue:
                                        tempModel,
                                  );

                                  if (result == null) return;

                                  modalSetState(() {
                                    tempModel = result;
                                  });
                                },
                      borderRadius:
                          BorderRadius.circular(14),
                      child: _filterBox(
                        title: widget.isArabic
                            ? 'الموديل'
                            : 'MODEL',
                        value: tempModel == 'ALL'
                            ? (widget.isArabic
                                ? 'اختر الموديل'
                                : 'SELECT MODEL')
                            : tempModel,
                        enabled: tempCategory != 'ALL',
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selectedBrand = 'ALL';
                                selectedType = 'ALL';
                                selectedCategory = 'ALL';
                                selectedModel = 'ALL';
                              });

                              Navigator.pop(context);
                            },
                            child: Text(
                              widget.isArabic
                                  ? 'إعادة تعيين'
                                  : 'RESET',
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: canApply
                                ? () {
                                    setState(() {
                                      selectedBrand =
                                          tempBrand;
                                      selectedType =
                                          tempType;
                                      selectedCategory =
                                          tempCategory;
                                      selectedModel =
                                          tempModel;
                                    });

                                    Navigator.pop(
                                      context,
                                    );
                                  }
                                : null,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red,
                              foregroundColor:
                                  Colors.white,
                              disabledBackgroundColor:
                                  Colors.grey.shade300,
                              disabledForegroundColor:
                                  Colors.grey.shade600,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 16,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),
                            child: Text(
                              canApply
                                  ? (widget.isArabic
                                      ? 'تطبيق الفلتر'
                                      : 'APPLY FILTER')
                                  : (widget.isArabic
                                      ? 'اختر الماركة والنوع والفئة والموديل'
                                      : 'SELECT BRAND, TYPE, CATEGORY & MODEL'),
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FILTER BOX
  // ============================================================

  Widget _filterBox({
    required String title,
    required String value,
    required bool enabled,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xfffafafa),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? Colors.grey.shade300
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: enabled
                          ? Colors.black87
                          : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled
                  ? Colors.black54
                  : Colors.black26,
            ),
          ],
        ),
      ),
      
    );
   }
     @override
  Widget build(BuildContext context) {
    final hs = homepageSettings.value;
    final heroTitle = widget.isArabic
        ? ((hs?['hero_title_ar'] as String?)?.trim().isNotEmpty == true
            ? hs!['hero_title_ar'] as String
            : 'سيارات المعرض')
        : ((hs?['hero_title_en'] as String?)?.trim().isNotEmpty == true
            ? hs!['hero_title_en'] as String
            : 'OUR CARS');
    final heroSubtitle = widget.isArabic
        ? ((hs?['hero_subtitle_ar'] as String?)?.trim().isNotEmpty == true
            ? hs!['hero_subtitle_ar'] as String
            : 'ابحث عن سيارتك واختر السيارة المناسبة')
        : ((hs?['hero_subtitle_en'] as String?)?.trim().isNotEmpty == true
            ? hs!['hero_subtitle_en'] as String
            : 'SEARCH AND FIND YOUR PERFECT CAR');
    return Stack(
      children: [
        SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
          Text(
            heroSubtitle,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          LayoutBuilder(
            builder: (context, sidebarConstraints) {
              final sidebar = _BrandsFilterSidebar(
                isArabic: widget.isArabic,
                brands: inventoryBrands
                    .where((b) => b != 'ALL')
                    .toList(),
                bodyTypesForBrand: _modelsForBrand,
                bodyTypeLabel: (value) => value,
                selectedBrand: selectedBrand,
                selectedBodyType: selectedCarName,
                expandedBrand: expandedSidebarBrand,
                onBrandExpandToggle: (brand) {
                  setState(() {
                    expandedSidebarBrand =
                        expandedSidebarBrand == brand ? null : brand;
                  });
                },
                onTypeSelected: (brand, type) {
                  setState(() {
                    selectedBrand = brand;
                    selectedCarName = type;
                  });
                },
                onClear: () {
                  setState(() {
                    selectedBrand = 'ALL';
                    selectedCarName = 'ALL';
                  });
                },
                onOpenAdvancedFilters: () => _showFilters(context),
              );

              final isWide = sidebarConstraints.maxWidth >= 900;

              final mainContent = Column(
                  children: [
          Row(
            children: [
              Expanded(
              child: Container(
                 height: 38,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.25),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: (value) {
                      setState(() {
                        search = value;
                      });
                    },
                    textAlign: widget.isArabic
                        ? TextAlign.right
                        : TextAlign.left,
                    decoration: InputDecoration(
                      hintText: widget.isArabic
                          ? 'ابحث عن سيارة...'
                          : 'Search for a car...',
                      hintStyle: const TextStyle(fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Container(
                height: 44,
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 14 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sortOption,
                    icon: const Icon(Icons.sort_rounded, size: 18),
                    items: [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text(
                          widget.isArabic ? 'الأحدث' : 'Newest',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text(
                          widget.isArabic
                              ? 'السعر: الأرخص أولًا'
                              : 'Price: Low to High',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text(
                          widget.isArabic
                              ? 'السعر: الأغلى أولًا'
                              : 'Price: High to Low',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => sortOption = value);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          LayoutBuilder(
  builder: (context, constraints) {
    int columns = 1;

    if (constraints.maxWidth >= 1400) {
      columns = 5;
    } else if (constraints.maxWidth >= 1100) {
      columns = 4;
    } else if (constraints.maxWidth >= 800) {
      columns = 2;
    } else {
      columns = 1;
    }

              final allFilteredCars = filteredCars;

              // لو الفلتر أو البحث اتغيّر، نرجع نعرض أول 25 سيارة بس
              // تاني بدل ما نفضل عارضين نفس العدد القديم على فلتر جديد.
              final currentSignature =
                  '$search|$selectedBrand|$selectedType|$selectedCategory|'
                  '$selectedModel|$showOffers|$minPrice|$maxPrice|$sortOption|$selectedBodyType';
              if (currentSignature != _lastFilterSignature) {
                _lastFilterSignature = currentSignature;
                _visibleCarsCount = _carsPerPage;
              }

              final visibleCars =
                  allFilteredCars.take(_visibleCarsCount).toList();

              if (filteredCars.isEmpty) {
                // لو قاعدة البيانات نفسها فاضية (فشل تحميل من الأساس)،
                // مش بس البحث/الفلتر مطلعش نتيجة، بنوري رسالة مختلفة
                // توضح إن المشكلة في الاتصال مش في البحث.
                if (cars.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 55,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 50,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isArabic
                              ? 'تعذّر تحميل السيارات، تأكد من اتصالك بالإنترنت'
                              : 'Failed to load cars, please check your internet connection',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 55,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 60,
                        color: Colors.black26,
                      ),

                      const SizedBox(height: 18),

                      Text(
                        widget.isArabic
                            ? 'لم نجد سيارة مطابقة لبحثك'
                            : 'NO MATCHING CARS FOUND',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        widget.isArabic
                            ? 'جرّب تغيير البحث أو خيارات الفلتر.'
                            : 'Try changing your search or filter options.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 18),

                      HoverLift(
                        borderRadius: BorderRadius.circular(10),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              search = '';
                              controller.clear();
                              showOffers = false;
                              selectedBrand = 'ALL';
                              selectedType = 'ALL';
                              selectedCategory = 'ALL';
                              selectedModel = 'ALL';
                            });
                          },
                          icon: const Icon(
                            Icons.filter_alt_off_rounded,
                            size: 18,
                          ),
                          label: Text(
                            widget.isArabic
                                ? 'مسح الفلاتر والرجوع للمعرض الكامل'
                                : 'Clear filters',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleCars.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final car = visibleCars[index];

                      return FeaturedCarCard(
                        key: ValueKey('${car.name}-${car.year}'),
                        car: car,
                        isArabic: widget.isArabic,
                      );
                    },
                  ),
                  if (_visibleCarsCount < allFilteredCars.length) ...[
                    const SizedBox(height: 30),
                    _ShowMoreCarsButton(
                      isArabic: widget.isArabic,
                      remaining: allFilteredCars.length - _visibleCarsCount,
                      onTap: () {
                        setState(() {
                          _visibleCarsCount += _carsPerPage;
                        });
                      },
                    ),
                  ],
                  if (_isLoadingMoreCars) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.isArabic
                              ? 'جاري تحميل باقي السيارات...'
                              : 'Loading more cars...',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
              ],
                );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sidebar,
                    const SizedBox(width: 20),
                    Expanded(child: mainContent),
                  ],
                );
              }
              // على الموبايل، الماركات بقت زرار صغير جنب البحث،
              // مش بلوك فوق الشبكة، فالشبكة تفضل في مكانها
              return mainContent;
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    ),
          AutoOneFooter(isArabic: widget.isArabic),
    ],
    ),
    ),

        // ================================================
        // BRANDS EDGE TAB (دليل ثابت في حافة الشاشة، موبايل بس)
        // ================================================
        if (!showMobileFilterDrawer)
          Positioned(
            top: 0,
            bottom: 0,
            right: widget.isArabic ? null : 0,
            left: widget.isArabic ? 0 : null,
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (screenWidth >= 900) return const SizedBox.shrink();
                return Center(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => showMobileFilterDrawer = true),
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      final opensToward =
                          widget.isArabic ? velocity > 0 : velocity < 0;
                      if (opensToward) {
                        setState(() => showMobileFilterDrawer = true);
                      }
                    },
                    child: Container(
                      width: 26,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: kBrandGradient,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.horizontal(
                          left: widget.isArabic
                              ? Radius.zero
                              : const Radius.circular(14),
                          right: widget.isArabic
                              ? const Radius.circular(14)
                              : Radius.zero,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_car_filled_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(height: 6),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              widget.isArabic ? 'الماركات' : 'BRANDS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // ================================================
        // MOBILE BRANDS DRAWER (فوق المحتوى، مع تعتيم خلفه)
        // ================================================
        if (showMobileFilterDrawer) ...[
          GestureDetector(
            onTap: () => setState(() => showMobileFilterDrawer = false),
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Align(
            alignment: widget.isArabic
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Material(
              elevation: 8,
              child: SizedBox(
                width: 280,
                height: double.infinity,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _BrandsFilterSidebar(
                      isArabic: widget.isArabic,
                      brands: inventoryBrands
                          .where((b) => b != 'ALL')
                          .toList(),
                      bodyTypesForBrand: _modelsForBrand,
                      bodyTypeLabel: (value) => value,
                      selectedBrand: selectedBrand,
                      selectedBodyType: selectedCarName,
                      expandedBrand: expandedSidebarBrand,
                      onBrandExpandToggle: (brand) {
                        setState(() {
                          expandedSidebarBrand =
                              expandedSidebarBrand == brand ? null : brand;
                        });
                      },
                      onTypeSelected: (brand, type) {
                        setState(() {
                          selectedBrand = brand;
                          selectedCarName = type;
                          showMobileFilterDrawer = false;
                        });
                      },
                      onClear: () {
                        setState(() {
                          selectedBrand = 'ALL';
                          selectedCarName = 'ALL';
                        });
                      },
                      onOpenAdvancedFilters: () {
                        setState(() => showMobileFilterDrawer = false);
                        _showFilters(context);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
   }

// ============================================================
// SHOW MORE CARS BUTTON (بهوية اوتو ون - نفس تدرج زرار الحجز)
// ============================================================
class _ShowMoreCarsButton extends StatelessWidget {
  final bool isArabic;
  final int remaining;
  final VoidCallback onTap;

  const _ShowMoreCarsButton({
    required this.isArabic,
    required this.remaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HoverLift(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'المزيد' : 'More',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// BRANDS FILTER SIDEBAR (عمود جانبي بجانب شبكة السيارات — كل
// ماركة ليها سهم يفتح أنواع الهيكل تحتها، ودوسة على نوع تفلتر
// السيارات فورًا في نفس الصفحة، من غير أي انتقال)
// ============================================================
class _BrandsFilterSidebar extends StatelessWidget {
  final bool isArabic;
  final List<String> brands;
  final List<String> Function(String brand) bodyTypesForBrand;
  final String Function(String value) bodyTypeLabel;
  final String selectedBrand;
  final String selectedBodyType;
  final String? expandedBrand;
  final ValueChanged<String> onBrandExpandToggle;
  final void Function(String brand, String type) onTypeSelected;
  final VoidCallback onClear;
  final VoidCallback onOpenAdvancedFilters;

  const _BrandsFilterSidebar({
    required this.isArabic,
    required this.brands,
    required this.bodyTypesForBrand,
    required this.bodyTypeLabel,
    required this.selectedBrand,
    required this.selectedBodyType,
    required this.expandedBrand,
    required this.onBrandExpandToggle,
    required this.onTypeSelected,
    required this.onClear,
    required this.onOpenAdvancedFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = selectedBrand != 'ALL' || selectedBodyType != 'ALL';

    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'الماركات' : 'Brands',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              if (hasActiveFilter)
                InkWell(
                  onTap: onClear,
                  child: Text(
                    isArabic ? 'مسح' : 'Clear',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final brand in brands) ...[
            _BrandRow(
              brand: brand,
              isExpanded: expandedBrand == brand,
              isSelectedNoType:
                  selectedBrand == brand && selectedBodyType == 'ALL',
              onHeaderTap: () => onBrandExpandToggle(brand),
              types: bodyTypesForBrand(brand),
              typeLabel: bodyTypeLabel,
              selectedType:
                  selectedBrand == brand ? selectedBodyType : null,
              onTypeTap: (type) => onTypeSelected(brand, type),
            ),
          ],
          const SizedBox(height: 6),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 4),
          InkWell(
            onTap: onOpenAdvancedFilters,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'فلاتر متقدمة' : 'Advanced filters',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  final String brand;
  final bool isExpanded;
  final bool isSelectedNoType;
  final VoidCallback onHeaderTap;
  final List<String> types;
  final String Function(String value) typeLabel;
  final String? selectedType;
  final ValueChanged<String> onTypeTap;

  const _BrandRow({
    required this.brand,
    required this.isExpanded,
    required this.isSelectedNoType,
    required this.onHeaderTap,
    required this.types,
    required this.typeLabel,
    required this.selectedType,
    required this.onTypeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onHeaderTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isExpanded || isSelectedNoType
                  ? Colors.red.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if ((brandLogosCache[brand] ?? '').isNotEmpty) ...[
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: carImageAdaptive(
                      brandLogosCache[brand]!,
                      fit: BoxFit.contain,
                      showWatermark: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    brand,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isExpanded || isSelectedNoType
                          ? Colors.red
                          : Colors.black87,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isExpanded ? Colors.red : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 14,
                    top: 4,
                    bottom: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final type in types)
                        InkWell(
                          onTap: () => onTypeTap(type),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  selectedType == type
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 18,
                                  color: selectedType == type
                                      ? Colors.red
                                      : Colors.black38,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  typeLabel(type),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (types.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            '—',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
