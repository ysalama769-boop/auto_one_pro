import 'dart:async';
import 'package:flutter/material.dart';
import '../models/car.dart';
import '../shared/repository.dart';
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

  const CarsPage({
    super.key,
    required this.isArabic,
    this.initialBrand,
    this.initialOffers = false,
  });

  @override
  State<CarsPage> createState() => _CarsPageState();
}


class _CarsPageState extends State<CarsPage> {
  String search = '';
  bool showOffers = false;

 String selectedBrand = 'ALL';

@override
void initState() {
  super.initState();

  selectedBrand = widget.initialBrand ?? 'ALL';
  showOffers = widget.initialOffers;
}
  String selectedType = 'ALL';
  String selectedCategory = 'ALL';
  String selectedModel = 'ALL';

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

      final price = _parsePrice(car.price);
      final matchesMinPrice = minPrice == null || price >= minPrice!;
      final matchesMaxPrice = maxPrice == null || price <= maxPrice!;

     return matchesSearch &&
    matchesBrand &&
    matchesType &&
    matchesCategory &&
    matchesModel &&
    matchesOffer &&
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
    final bannerImages = (hs?['banner_images'] is List)
        ? List<String>.from(
            (hs!['banner_images'] as List).map((e) => e.toString()))
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          if (bannerImages.isNotEmpty) ...[
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: PageView.builder(
                  itemCount: bannerImages.length,
                  itemBuilder: (context, index) {
                    return carImageAdaptive(
                      bannerImages[index],
                      fit: BoxFit.cover,
                      showWatermark: false,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            heroSubtitle,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
              child: Container(
                 height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
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
                      prefixIcon:
                          const Icon(Icons.search_rounded),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              ElevatedButton.icon(
                onPressed: () => _showFilters(context),
                icon: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  widget.isArabic ? 'فلتر' : 'FILTER',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(110, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // SORT + PRICE RANGE
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
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

              SizedBox(
                width: 130,
                height: 44,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: widget.isArabic ? 'أقل سعر' : 'Min price',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      minPrice = double.tryParse(value);
                    });
                  },
                ),
              ),

              SizedBox(
                width: 130,
                height: 44,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: widget.isArabic ? 'أعلى سعر' : 'Max price',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      maxPrice = double.tryParse(value);
                    });
                  },
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
                  '$selectedModel|$showOffers|$minPrice|$maxPrice|$sortOption';
              if (currentSignature != _lastFilterSignature) {
                _lastFilterSignature = currentSignature;
                _visibleCarsCount = _carsPerPage;
              }

              final visibleCars =
                  allFilteredCars.take(_visibleCarsCount).toList();

              if (filteredCars.isEmpty) {
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
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          AutoOneFooter(isArabic: widget.isArabic),
        ],
      ),
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

