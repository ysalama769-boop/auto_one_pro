import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../shared/car_specs_schema.dart';
import '../admin/admin_shared.dart';

// ============================================================
// ADMIN INVENTORY (CARS CRUD)
// ============================================================

// مواصفة إضافية حرة مربوطة بقسم معيّن (القيادة، الأمان...) بدل ما
// تكون في مجموعة واحدة عامة من غير تصنيف.
class ExtraSpecEntry {
  final String category;
  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;

  ExtraSpecEntry({
    required this.category,
    required this.keyCtrl,
    required this.valueCtrl,
  });
}
class AdminCarsPage extends StatefulWidget {
  final bool isArabic;
  // لو موجودة، الصفحة بتعرض بس سيارات الماركة دي (بدل كل المخزون)،
  // ولما تضيفي سيارة جديدة من هنا، الماركة بتتحدد أوتوماتيك.
  final String? filterBrand;

  const AdminCarsPage({super.key, required this.isArabic, this.filterBrand});

  @override
  State<AdminCarsPage> createState() => _AdminCarsPageState();
}


class _AdminCarsPageState extends State<AdminCarsPage> {
  List<Map<String, dynamic>> inventoryCars = [];
  bool isLoading = true;
  String? errorMessage;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // القايمة محتاجة بس الأعمدة اللي بتتعرض فعليًا (مش كل تفاصيل
      // السيارة الكاملة زي المواصفات والوصف)، وده بيقلل حجم البيانات
      // اللي بتتحمّل بشكل كبير خصوصًا لو عندك عدد كبير من السيارات.
      final query = Supabase.instance.client
          .from('cars')
          .select(
            'id, brand, name, price, year, image, is_available, car_status, sort_order',
          );

      final filteredQuery = widget.filterBrand == null
          ? query
          // بنستخدم ilike بدل eq عشان الفلترة تتجاهل الفرق بين
          // الأحرف الكبيرة والصغيرة (Hyundai / hyundai / HYUNDAI
          // كلهم يتطابقوا مع بعض)
          : query.ilike('brand', widget.filterBrand as String);

      final response = await filteredQuery
          .order('sort_order', nullsFirst: false)
          .order('id', ascending: false);

      setState(() {
        inventoryCars = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage =
            isArabic ? 'تعذّر تحميل السيارات' : 'Failed to load cars';
        isLoading = false;
      });
    }
  }

  Future<void> _moveCar(int index, int direction) async {
    final targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= inventoryCars.length) return;

    final updated = List<Map<String, dynamic>>.from(inventoryCars);
    final temp = updated[index];
    updated[index] = updated[targetIndex];
    updated[targetIndex] = temp;

    setState(() => inventoryCars = updated);

    final payload = [
      for (var i = 0; i < updated.length; i++)
        {'id': updated[i]['id'], 'sort_order': i},
    ];

    try {
      await Supabase.instance.client.from('cars').upsert(payload);
    } catch (e) {
      // لو فشل، نرجع نحمّل القايمة الأصلية من قاعدة البيانات
      _loadCars();
    }
  }

  Future<void> _duplicateCar(Map<String, dynamic> car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'نسخ السيارة' : 'Duplicate car'),
        content: Text(
          isArabic
              ? 'هيتعمل نسخة جديدة من "${car['name'] ?? ''}" تقدري تعدّلي فيها.'
              : 'A new copy of "${car['name'] ?? ''}" will be created for you to edit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isArabic ? 'نسخ' : 'Duplicate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // القائمة عندها بيانات مختصرة بس، فلازم نجيب صف السيارة كامل
      // قبل ما نعمل نسخة منه (وإلا هتتعمل نسخة ناقصة مواصفات).
      final fullCar = await Supabase.instance.client
          .from('cars')
          .select()
          .eq('id', car['id'])
          .single();

      final newCarData = Map<String, dynamic>.from(fullCar);
      final oldId = newCarData.remove('id');
      newCarData.remove('created_at');
      newCarData['name'] =
          '${newCarData['name'] ?? ''} ${isArabic ? "(نسخة)" : "(Copy)"}';
      newCarData['sort_order'] = null;

      final inserted = await Supabase.instance.client
          .from('cars')
          .insert(newCarData)
          .select()
          .single();
      final newId = inserted['id'];

      // ننسخ الصور الإضافية كمان لو موجودة
      try {
        final images = await Supabase.instance.client
            .from('car_images')
            .select('image')
            .eq('car_id', oldId);
        final imagesList = List<Map<String, dynamic>>.from(images as List);
        if (imagesList.isNotEmpty) {
          await Supabase.instance.client.from('car_images').insert(
                imagesList
                    .map((row) => {'car_id': newId, 'image': row['image']})
                    .toList(),
              );
        }
      } catch (e) {
        // لو فشل نسخ الصور، السيارة نفسها اتنسخت وده الأهم
      }

      await logActivity(
        isArabic
            ? 'نسخ سيارة: ${car['name']} (نسخة جديدة)'
            : 'Duplicated car: ${car['name']} (new copy)',
      );

      _loadCars();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'حصلت مشكلة' : 'Something went wrong'),
        ),
      );
    }
  }

  Future<void> _deleteCar(int id, {String? carName}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm delete'),
        content: Text(
          isArabic
              ? 'متأكدة إنك عايزة تمسحي "${carName ?? ""}" نهائيًا؟'
              : 'Permanently delete "${carName ?? ""}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isArabic ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // بنمسح البيانات المساعدة المرتبطة بالسيارة الأول (صور وألوان)
      // عشان متعملش مشكلة قيد ربط (foreign key) لما نمسح السيارة نفسها
      await Supabase.instance.client
          .from('car_images')
          .delete()
          .eq('car_id', id);
      await Supabase.instance.client
          .from('car_color_availability')
          .delete()
          .eq('car_id', id);

      await Supabase.instance.client.from('cars').delete().eq('id', id);
      await logActivity(
        isArabic
            ? 'حذف السيارة: ${carName ?? id}'
            : 'Deleted car: ${carName ?? id}',
      );
      _loadCars();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final isForeignKeyError =
          e.code == '23503' || e.message.toLowerCase().contains('foreign key');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isForeignKeyError
                ? (isArabic
                    ? 'السيارة دي مرتبطة بحجوزات أو طلبات فعلية، فمتقدرش تتمسح خالص. تقدر تعطّلها (تخفيها من الموقع) من نموذج التعديل بدل ما تحذفها.'
                    : 'This car has existing bookings or requests linked to it, so it can\'t be deleted. You can deactivate it (hide it from the site) from the edit form instead.')
                : (isArabic
                    ? 'حصلت مشكلة: ${e.message}'
                    : 'Something went wrong: ${e.message}'),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'حصلت مشكلة: $e' : 'Something went wrong: $e',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _openForm({Map<String, dynamic>? existingCar}) async {
    var fullCar = existingCar;

    // القائمة عندها بيانات مختصرة بس (عشان السرعة)، فلو بنعدّل سيارة
    // موجودة فعلاً، لازم نجيب بياناتها الكاملة الأول قبل ما نفتح الفورم.
    if (existingCar != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        fullCar = await Supabase.instance.client
            .from('cars')
            .select()
            .eq('id', existingCar['id'])
            .single();
      } catch (e) {
        fullCar = existingCar; // على الأقل نفتح بالبيانات المختصرة لو فشل
      }
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    final saved = await Navigator.of(context).push<bool>(
      smoothRoute(
        CarFormPage(
          isArabic: isArabic,
          existingCar: fullCar,
          lockedBrand: existingCar == null ? widget.filterBrand : null,
        ),
      ),
    );

    if (saved == true) {
      _loadCars();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: widget.filterBrand == null
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,
              title: Text(
                isArabic
                    ? 'سيارات ${widget.filterBrand}'
                    : '${widget.filterBrand} cars',
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'adminCarsPageFAB',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(isArabic ? 'سيارة جديدة' : 'New car'),
      ),
      body: isLoading
          ? skeletonCardList()
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : inventoryCars.isEmpty
                  ? Center(
                      child: Text(
                        widget.filterBrand != null
                            ? (isArabic
                                ? 'مفيش سيارات لماركة ${widget.filterBrand} لسه'
                                : 'No cars for ${widget.filterBrand} yet')
                            : (isArabic
                                ? 'مفيش سيارات في المخزون لسه'
                                : 'No cars in inventory yet'),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: inventoryCars.length,
                      itemBuilder: (context, index) {
                        final carData = inventoryCars[index];
                        final isAvailable =
                            (carData['is_available'] ?? true) as bool;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: carImageAdaptive(
                                      (carData['image'] ?? '') as String,
                                      fit: BoxFit.cover,
                                      showWatermark: false,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${carData['brand'] ?? ''} ${carData['name'] ?? ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${carData['price'] ?? ''} • ${carData['year'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                        Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (isAvailable
                                                  ? Colors.green
                                                  : Colors.grey)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isAvailable
                                              ? (isArabic
                                                  ? 'متاحة'
                                                  : 'Available')
                                              : (isArabic
                                                  ? 'غير متاحة'
                                                  : 'Unavailable'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isAvailable
                                                ? Colors.green
                                                : Colors.black54,
                                          ),
                                        ),
                                      ),
                                      Builder(builder: (context) {
                                        final status =
                                            (carData['car_status'] ??
                                                    'available')
                                                as String;
                                        final statusColor = status == 'sold'
                                            ? Colors.red
                                            : status == 'reserved'
                                                ? Colors.orange
                                                : Colors.blue;
                                        final statusLabel = status == 'sold'
                                            ? (isArabic ? 'مباعة' : 'Sold')
                                            : status == 'reserved'
                                                ? (isArabic
                                                    ? 'محجوزة'
                                                    : 'Reserved')
                                                : (isArabic
                                                    ? 'بالمخزون'
                                                    : 'In stock');
                                        return Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                            ),
                                          ),
                                        );
                                      }),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      onPressed: index == 0
                                          ? null
                                          : () => _moveCar(index, -1),
                                      icon: Icon(
                                        Icons.keyboard_arrow_up_rounded,
                                        color: index == 0
                                            ? Colors.black26
                                            : Colors.black87,
                                      ),
                                      tooltip: isArabic ? 'لأعلى' : 'Move up',
                                    ),
                                    IconButton(
                                      onPressed:
                                          index == inventoryCars.length - 1
                                              ? null
                                              : () => _moveCar(index, 1),
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: index ==
                                                inventoryCars.length - 1
                                            ? Colors.black26
                                            : Colors.black87,
                                      ),
                                      tooltip:
                                          isArabic ? 'لأسفل' : 'Move down',
                                    ),
                                    IconButton(
                                      onPressed: () => _duplicateCar(carData),
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        color: Colors.orange,
                                      ),
                                      tooltip: isArabic ? 'نسخ' : 'Duplicate',
                                    ),
                                    IconButton(
                                      onPressed: () => _openForm(
                                        existingCar: carData,
                                      ),
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteCar(
                                        carData['id'] as int,
                                        carName:
                                            '${carData['brand'] ?? ''} ${carData['name'] ?? ''}'
                                                .trim(),
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}


// ============================================================
// CAR FORM (ADD / EDIT)
// ============================================================
class CarFormPage extends StatefulWidget {
  final bool isArabic;
  final Map<String, dynamic>? existingCar;
  // لو موجودة، الماركة بتتحدد أوتوماتيك وبتتقفل (مش قابلة للتعديل)
  // — مستخدمة لما السيارة بتتضاف من جوه صفحة ماركة معيّنة، عشان
  // محدش يحتاج يختار الماركة يدوي من قايمة كل الماركات في كل مرة.
  final String? lockedBrand;

  const CarFormPage({
    super.key,
    required this.isArabic,
    this.existingCar,
    this.lockedBrand,
  });

  @override
  State<CarFormPage> createState() => _CarFormPageState();
}


class _CarFormPageState extends State<CarFormPage> {
  final formKey = GlobalKey<FormState>();
  bool _isUploadingImage = false;

  late final TextEditingController nameCtrl;
  late final TextEditingController nameEnCtrl;
  late final TextEditingController brandCtrl;
  late final TextEditingController categoryCtrl;
  late final TextEditingController yearCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController descriptionCtrl;
  late final TextEditingController descriptionEnCtrl;
  late final TextEditingController imageCtrl;
  late final TextEditingController seatsCtrl;
  late final TextEditingController engineCtrl;
  late final TextEditingController transmissionCtrl;
  late final TextEditingController fuelCtrl;
  late final TextEditingController driveCtrl;
  late final TextEditingController lengthCtrl;
  late final TextEditingController widthCtrl;
  late final TextEditingController heightCtrl;
  late final TextEditingController wheelbaseCtrl;
  late final TextEditingController trunkCapacityCtrl;
  late final TextEditingController horsepowerCtrl;
  late final TextEditingController torqueCtrl;
  late final TextEditingController fuelTankCtrl;
  late final TextEditingController fuelConsumptionCtrl;
  late final TextEditingController infotainmentCtrl;
  late final TextEditingController sunroofCtrl;
  late final TextEditingController cameraSensorsCtrl;
  late final TextEditingController wirelessChargerCtrl;
  late final TextEditingController airbagsCtrl;
  late final TextEditingController absSystemCtrl;

  late bool isAvailable;
  late bool isOffer;
  late bool wasOfferInitially;
  late bool isFeatured;
  late final TextEditingController oldPriceCtrl;
  late final TextEditingController discountPercentCtrl;
  late final TextEditingController offerStartDateCtrl;
  late final TextEditingController offerEndDateCtrl;
  bool isSaving = false;

  // حالة السيارة + بيانات المخزون
  late String carStatusValue; // available | reserved | sold
  late String conditionStatusValue; // new | used
  late final TextEditingController vinCtrl;
  late final TextEditingController plateNumberCtrl;
  late final TextEditingController locationCtrl;
  late final TextEditingController arrivalDateCtrl;

  // مواصفات إضافية مرنة، كل واحدة مربوطة بقسم (القيادة، الأمان...)
  List<ExtraSpecEntry> extraSpecEntries = [];

  // قيم الـ40 بند المعروفة (من car_specs_schema.dart) — key البند
  // نفسه هو المفتاح، والقيمة زي ما هتتخزن (مثلاً "led"، أو "true"
  // للبنود اللي نوعها toggle، أو "electric,heated" للمتعدد الاختيار)
  Map<String, String> structuredSpecValues = {};

  // الألوان المتاحة في المتجر كله، وإيه اللي متحدد للسيارة دي
  List<Map<String, dynamic>> allColors = [];
  List<Map<String, dynamic>> allBrands = [];
  Set<int> selectedColorIds = {};
  // لكل لون: قايمة صور خارجية وقايمة صور داخلية منفصلة (معرض كامل
  // مش صورة واحدة بس)
  Map<int, List<TextEditingController>> colorExteriorImageControllers = {};
  Map<int, List<TextEditingController>> colorInteriorImageControllers = {};
  bool isLoadingExtras = true;

  // صور إضافية للمعرض (غير الصورة الأساسية)
  List<TextEditingController> extraImageControllers = [];

  bool get isArabic => widget.isArabic;
  bool get isEditing => widget.existingCar != null;

  @override
  void initState() {
    super.initState();
    final car = widget.existingCar;

    nameCtrl = TextEditingController(text: car?['name']?.toString() ?? '');
    nameEnCtrl =
        TextEditingController(text: car?['name_en']?.toString() ?? '');
    brandCtrl = TextEditingController(
      text: widget.lockedBrand ?? car?['brand']?.toString() ?? '',
    );
    categoryCtrl =
        TextEditingController(text: car?['category']?.toString() ?? '');
    yearCtrl = TextEditingController(text: car?['year']?.toString() ?? '');
    priceCtrl = TextEditingController(text: car?['price']?.toString() ?? '');
    descriptionCtrl =
        TextEditingController(text: car?['description']?.toString() ?? '');
    descriptionEnCtrl = TextEditingController(
        text: car?['description_en']?.toString() ?? '');
    imageCtrl = TextEditingController(text: car?['image']?.toString() ?? '');
    seatsCtrl = TextEditingController(text: car?['seats']?.toString() ?? '5');
    engineCtrl =
        TextEditingController(text: car?['engine']?.toString() ?? '1.5L');
    transmissionCtrl = TextEditingController(
      text: car?['transmission']?.toString() ?? 'أوتوماتيك',
    );
    fuelCtrl =
        TextEditingController(text: car?['fuel']?.toString() ?? 'بنزين');
    driveCtrl = TextEditingController(
      text: car?['drive']?.toString() ?? 'دفع أمامي',
    );
    lengthCtrl =
        TextEditingController(text: car?['car_length']?.toString() ?? '');
    widthCtrl =
        TextEditingController(text: car?['car_width']?.toString() ?? '');
    heightCtrl =
        TextEditingController(text: car?['car_height']?.toString() ?? '');
    wheelbaseCtrl =
        TextEditingController(text: car?['wheelbase']?.toString() ?? '');
    trunkCapacityCtrl = TextEditingController(
        text: car?['trunk_capacity']?.toString() ?? '');
    horsepowerCtrl =
        TextEditingController(text: car?['horsepower']?.toString() ?? '');
    torqueCtrl =
        TextEditingController(text: car?['torque']?.toString() ?? '');
    fuelTankCtrl =
        TextEditingController(text: car?['fuel_tank']?.toString() ?? '');
    fuelConsumptionCtrl = TextEditingController(
        text: car?['fuel_consumption']?.toString() ?? '');
    infotainmentCtrl = TextEditingController(
        text: car?['infotainment']?.toString() ?? '');
    sunroofCtrl =
        TextEditingController(text: car?['sunroof']?.toString() ?? '');
    cameraSensorsCtrl = TextEditingController(
        text: car?['camera_sensors']?.toString() ?? '');
    wirelessChargerCtrl = TextEditingController(
        text: car?['wireless_charger']?.toString() ?? '');
    airbagsCtrl =
        TextEditingController(text: car?['airbags']?.toString() ?? '');
    absSystemCtrl =
        TextEditingController(text: car?['abs_system']?.toString() ?? '');

    isAvailable = (car?['is_available'] ?? true) as bool;
    isOffer = (car?['is_offer'] ?? false) as bool;
    wasOfferInitially = isOffer;
    isFeatured = (car?['is_featured'] ?? false) as bool;
    oldPriceCtrl =
        TextEditingController(text: car?['old_price']?.toString() ?? '');
    discountPercentCtrl = TextEditingController(
        text: car?['discount_percent']?.toString() ?? '');
    offerStartDateCtrl = TextEditingController(
        text: car?['offer_start_date']?.toString() ?? '');
    offerEndDateCtrl = TextEditingController(
        text: car?['offer_end_date']?.toString() ?? '');

    carStatusValue = (car?['car_status'] ?? 'available') as String;
    conditionStatusValue = (car?['condition_status'] ?? 'new') as String;
    vinCtrl = TextEditingController(text: car?['vin']?.toString() ?? '');
    plateNumberCtrl =
        TextEditingController(text: car?['plate_number']?.toString() ?? '');
    locationCtrl =
        TextEditingController(text: car?['location']?.toString() ?? '');
    arrivalDateCtrl =
        TextEditingController(text: car?['arrival_date']?.toString() ?? '');

    final rawExtraSpecs = car?['extra_specs'];
    if (rawExtraSpecs is Map) {
      rawExtraSpecs.forEach((catKey, catValue) {
        if (catValue is Map) {
          // النسخة الجديدة: مواصفات مقسّمة على أقسام
          catValue.forEach((k, v) {
            // لو المفتاح ده من ضمن الـ40 بند المعروفة في الشيما،
            // بيتحط في structuredSpecValues (هيتعرض بالواجهة
            // المنظّمة)، مش في القايمة الحرة القديمة.
            if (findCarSpecItem(k.toString()) != null) {
              structuredSpecValues[k.toString()] = v.toString();
            } else {
              extraSpecEntries.add(
                ExtraSpecEntry(
                  category: catKey.toString(),
                  keyCtrl: TextEditingController(text: k.toString()),
                  valueCtrl: TextEditingController(text: v.toString()),
                ),
              );
            }
          });
        } else {
          // بيانات قديمة كانت مسطّحة من غير أقسام — نحطها تحت "أخرى"
          extraSpecEntries.add(
            ExtraSpecEntry(
              category: isArabic ? 'أخرى' : 'Other',
              keyCtrl: TextEditingController(text: catKey.toString()),
              valueCtrl: TextEditingController(text: catValue.toString()),
            ),
          );
        }
      });
    }

    // البنود القديمة اللي بقت جوه الواجهة المنظّمة (الوقود، الناقل،
    // الدفع، المقاعد، الوسائد، ABS، فتحة السقف، الشاحن اللاسلكي)
    // قيمتها الأصلية متخزنة في أعمدتها الحقيقية، فبنجيبها من نفس
    // الكنترولرز اللي جهزوها فوق، مش من extra_specs.
    void loadColumnBacked(String key, TextEditingController ctrl) {
      final value = ctrl.text.trim();
      if (value.isNotEmpty) {
        structuredSpecValues[key] = value;
      }
    }

    loadColumnBacked('fuel', fuelCtrl);
    loadColumnBacked('transmission', transmissionCtrl);
    loadColumnBacked('drive', driveCtrl);
    loadColumnBacked('seats', seatsCtrl);
    loadColumnBacked('sunroof', sunroofCtrl);
    loadColumnBacked('airbags', airbagsCtrl);
    // دول توجل/تفعيل بس (نص حر قديم)، فأي قيمة غير فاضية معناها "مفعّل"
    if (wirelessChargerCtrl.text.trim().isNotEmpty) {
      structuredSpecValues['wireless_charger'] = 'true';
    }
    if (absSystemCtrl.text.trim().isNotEmpty) {
      structuredSpecValues['abs_system'] = 'true';
    }

    _loadExtras();
  }

  // بيجيب كل الألوان المتاحة، وألوان/صور السيارة دي لو بنعدّل
  Future<void> _loadExtras() async {
    try {
      final colorsResponse =
          await Supabase.instance.client.from('colors').select();
      allColors = List<Map<String, dynamic>>.from(colorsResponse as List);

      final brandsResponse = await Supabase.instance.client
          .from('brands')
          .select()
          .order('name_en');
      allBrands = List<Map<String, dynamic>>.from(brandsResponse as List);

      if (isEditing) {
        final carId = widget.existingCar!['id'] as int;

        final carColorsResponse = await Supabase.instance.client
            .from('car_color_availability')
            .select('color_id, image, exterior_images, interior_images')
            .eq('car_id', carId)
            .eq('is_available', true);

        selectedColorIds = (carColorsResponse as List)
            .map((row) => row['color_id'] as int)
            .toSet();

        for (final row in carColorsResponse) {
          final colorId = row['color_id'] as int;

          final exteriorList = (row['exterior_images'] is List)
              ? List<String>.from(
                  (row['exterior_images'] as List).map((e) => e.toString()),
                )
              : <String>[];
          // توافق مع البيانات القديمة: لو مفيش exterior_images بس فيه
          // "image" قديمة، نحطها كأول صورة خارجية
          if (exteriorList.isEmpty &&
              (row['image'] ?? '').toString().trim().isNotEmpty) {
            exteriorList.add((row['image'] as String).trim());
          }

          final interiorList = (row['interior_images'] is List)
              ? List<String>.from(
                  (row['interior_images'] as List).map((e) => e.toString()),
                )
              : <String>[];

          colorExteriorImageControllers[colorId] = exteriorList
              .map((url) => TextEditingController(text: url))
              .toList();
          colorInteriorImageControllers[colorId] = interiorList
              .map((url) => TextEditingController(text: url))
              .toList();
        }

        final carImagesResponse = await Supabase.instance.client
            .from('car_images')
            .select('image')
            .eq('car_id', carId);

        extraImageControllers = (carImagesResponse as List)
            .map((row) => TextEditingController(
                  text: (row['image'] ?? '').toString(),
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('AUTO_ONE_DEBUG: تعذّر تحميل الألوان/الصور: $e');
    }

    if (mounted) {
      setState(() => isLoadingExtras = false);
    }
  }

  // بيفتح نافذة اختيار ملف من جهاز المستخدم (بتشمل الديسكتوب وأي فولدر
  // تاني)، وبعد الاختيار بيرفع الصورة على نفس مكان تخزين الصور في
  // Supabase (bucket اسمه car_images) وبعدين يحط الرابط الناتج تلقائيًا
  // في أي خانة رابط صورة تحددهالها (الصورة الأساسية، صورة إضافية،
  // أو صورة لون معيّن).
  Future<void> _pickAndUploadImage(TextEditingController targetCtrl) async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];

      setState(() => _isUploadingImage = true);

      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        final rawBytes = reader.result as Uint8List;
        // صور السيارات هي أكبر مصدر لوزن الصفحة، فبنضغطها قبل الرفع
        final bytes = await compressImageBytes(rawBytes);

        final brandFolder = brandCtrl.text.trim().isEmpty
            ? 'other'
            : brandCtrl.text.trim().toLowerCase().replaceAll(
                  RegExp(r'[^\w\-]'),
                  '_',
                );
        final modelFolder = nameCtrl.text.trim().isEmpty
            ? 'general'
            : nameCtrl.text.trim().toLowerCase().replaceAll(
                  RegExp(r'[^\w\-]'),
                  '_',
                );
        final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final path =
            '$brandFolder/$modelFolder/${DateTime.now().millisecondsSinceEpoch}_$safeName';

        await Supabase.instance.client.storage.from('car_images').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );

        final publicUrl = Supabase.instance.client.storage
            .from('car_images')
            .getPublicUrl(path);

        if (mounted) {
          setState(() {
            targetCtrl.text = publicUrl;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'فشل رفع الصورة: $e'
                    : 'Failed to upload image: $e',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    nameEnCtrl.dispose();
    brandCtrl.dispose();
    categoryCtrl.dispose();
    yearCtrl.dispose();
    priceCtrl.dispose();
    descriptionCtrl.dispose();
    descriptionEnCtrl.dispose();
    imageCtrl.dispose();
    seatsCtrl.dispose();
    engineCtrl.dispose();
    transmissionCtrl.dispose();
    fuelCtrl.dispose();
    driveCtrl.dispose();
    lengthCtrl.dispose();
    widthCtrl.dispose();
    heightCtrl.dispose();
    wheelbaseCtrl.dispose();
    trunkCapacityCtrl.dispose();
    horsepowerCtrl.dispose();
    torqueCtrl.dispose();
    fuelTankCtrl.dispose();
    fuelConsumptionCtrl.dispose();
    infotainmentCtrl.dispose();
    sunroofCtrl.dispose();
    cameraSensorsCtrl.dispose();
    wirelessChargerCtrl.dispose();
    airbagsCtrl.dispose();
    absSystemCtrl.dispose();
    oldPriceCtrl.dispose();
    discountPercentCtrl.dispose();
    offerStartDateCtrl.dispose();
    offerEndDateCtrl.dispose();
    vinCtrl.dispose();
    plateNumberCtrl.dispose();
    locationCtrl.dispose();
    arrivalDateCtrl.dispose();
    for (final entry in extraSpecEntries) {
      entry.keyCtrl.dispose();
      entry.valueCtrl.dispose();
    }
    for (final controller in extraImageControllers) {
      controller.dispose();
    }
    for (final list in colorExteriorImageControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final list in colorInteriorImageControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  // قايمة صور صغيرة (خارجية أو داخلية) لنفس اللون — إضافة/حذف/رفع
  // من الجهاز لكل صورة.
  Widget _colorImageGallerySection({
    required String label,
    required List<TextEditingController> controllers,
    required StateSetter setDialogState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setDialogState(() {
                  setState(() {
                    controllers.add(TextEditingController());
                  });
                });
              },
              icon: const Icon(Icons.add_circle_rounded, color: Colors.red),
              iconSize: 20,
            ),
          ],
        ),
        for (final controller in controllers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: isArabic ? 'رابط الصورة' : 'Image link',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isUploadingImage
                      ? null
                      : () => _pickAndUploadImage(controller),
                  icon: const Icon(Icons.upload_file),
                  tooltip: isArabic ? 'اختيار من الجهاز' : 'Browse',
                ),
                IconButton(
                  onPressed: () {
                    setDialogState(() {
                      setState(() {
                        controller.dispose();
                        controllers.remove(controller);
                      });
                    });
                  },
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _openColorsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isArabic ? 'إدارة الألوان' : 'Manage colors'),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'دوسي على أي لون عشان تحدديه كمتاح لهذه السيارة'
                            : 'Tap a color to mark it available for this car',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isLoadingExtras)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.red,
                            ),
                          ),
                        )
                      else if (allColors.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            isArabic
                                ? 'مفيش ألوان مسجلة في جدول colors لسه'
                                : 'No colors registered in the colors table yet',
                            style: const TextStyle(color: Colors.black45),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: allColors.map((color) {
                            final colorId = color['id'] as int;
                            final isSelected =
                                selectedColorIds.contains(colorId);
                            final rawValue =
                                (color['color_value'] as int?) ?? 0xFFFFFF;
                            final displayColor = Color(0xFF000000 | rawValue);
                            final name = isArabic
                                ? (color['name_ar'] ?? '') as String
                                : (color['name_en'] ?? '') as String;

                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  setState(() {
                                    if (isSelected) {
                                      selectedColorIds.remove(colorId);
                                      for (final c
                                          in colorExteriorImageControllers[
                                                  colorId] ??
                                              []) {
                                        c.dispose();
                                      }
                                      for (final c
                                          in colorInteriorImageControllers[
                                                  colorId] ??
                                              []) {
                                        c.dispose();
                                      }
                                      colorExteriorImageControllers
                                          .remove(colorId);
                                      colorInteriorImageControllers
                                          .remove(colorId);
                                    } else {
                                      selectedColorIds.add(colorId);
                                      colorExteriorImageControllers
                                          .putIfAbsent(colorId, () => []);
                                      colorInteriorImageControllers
                                          .putIfAbsent(colorId, () => []);
                                    }
                                  });
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.red.withValues(alpha: 0.08)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.red
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: displayColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      name,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 15,
                                        color: Colors.red,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      if (selectedColorIds.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ...selectedColorIds.map((colorId) {
                          final colorData = allColors.firstWhere(
                            (c) => c['id'] == colorId,
                            orElse: () => {},
                          );
                          final rawValue =
                              (colorData['color_value'] as int?) ?? 0xFFFFFF;
                          final displayColor = Color(0xFF000000 | rawValue);
                          final name = isArabic
                              ? (colorData['name_ar'] ?? '') as String
                              : (colorData['name_en'] ?? '') as String;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: displayColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _colorImageGallerySection(
                                  label: isArabic
                                      ? 'صور خارجية'
                                      : 'Exterior photos',
                                  controllers:
                                      colorExteriorImageControllers
                                          .putIfAbsent(colorId, () => []),
                                  setDialogState: setDialogState,
                                ),
                                const SizedBox(height: 10),
                                _colorImageGallerySection(
                                  label: isArabic
                                      ? 'صور داخلية'
                                      : 'Interior photos',
                                  controllers:
                                      colorInteriorImageControllers
                                          .putIfAbsent(colorId, () => []),
                                  setDialogState: setDialogState,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isArabic ? 'تم' : 'Done'),
                ),
              ],
            );
          },
        );
      },
    );
    // نحدّث الفورم الرئيسي عشان يعرض ملخص الألوان الجديد
    setState(() {});
  }

  Widget _bodyTypeChip(String value, String label) {
    final isSelected = categoryCtrl.text.trim().toUpperCase() == value;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          categoryCtrl.text = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.black12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }


  Future<void> _openGalleryDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                isArabic ? 'إدارة صور المعرض' : 'Manage gallery photos',
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              // ==========================================
              // EXTRA IMAGES SECTION
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'صور إضافية للمعرض' : 'Extra gallery photos',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setDialogState(() {
                        setState(() {
                          extraImageControllers.add(TextEditingController());
                        });
                      });
                    },
                    icon: const Icon(
                      Icons.add_circle_rounded,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              if (extraImageControllers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isArabic
                        ? 'مفيش صور إضافية، دوسي + عشان تضيفي'
                        : 'No extra photos, tap + to add one',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ),
              ...extraImageControllers.asMap().entries.map((entry) {
                final controller = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: isArabic
                                ? 'رابط صورة إضافية'
                                : 'Extra image link',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isUploadingImage
                            ? null
                            : () => _pickAndUploadImage(controller),
                        icon: const Icon(Icons.upload_file),
                        tooltip: isArabic ? 'اختيار من الجهاز' : 'Browse',
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                        setState(() {
                          controller.dispose();
                          extraImageControllers.remove(controller);
                        });
                      });
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),

                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isArabic ? 'تم' : 'Done'),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final data = {
      'name': nameCtrl.text.trim(),
      'name_en': nameEnCtrl.text.trim(),
      'brand': brandCtrl.text.trim(),
      'category': categoryCtrl.text.trim(),
      'year': yearCtrl.text.trim(),
      'price': priceCtrl.text.trim(),
      'description': descriptionCtrl.text.trim(),
      'description_en': descriptionEnCtrl.text.trim(),
      'image': imageCtrl.text.trim(),
      'seats': seatsCtrl.text.trim(),
      'engine': engineCtrl.text.trim(),
      'transmission': transmissionCtrl.text.trim(),
      'fuel': fuelCtrl.text.trim(),
      'drive': driveCtrl.text.trim(),
      'car_length': lengthCtrl.text.trim(),
      'car_width': widthCtrl.text.trim(),
      'car_height': heightCtrl.text.trim(),
      'wheelbase': wheelbaseCtrl.text.trim(),
      'trunk_capacity': trunkCapacityCtrl.text.trim(),
      'horsepower': horsepowerCtrl.text.trim(),
      'torque': torqueCtrl.text.trim(),
      'fuel_tank': fuelTankCtrl.text.trim(),
      'fuel_consumption': fuelConsumptionCtrl.text.trim(),
      'infotainment': infotainmentCtrl.text.trim(),
      'sunroof': sunroofCtrl.text.trim(),
      'camera_sensors': cameraSensorsCtrl.text.trim(),
      'wireless_charger': wirelessChargerCtrl.text.trim(),
      'airbags': airbagsCtrl.text.trim(),
      'abs_system': absSystemCtrl.text.trim(),
      'is_offer': isOffer,
      'is_featured': isFeatured,
      'old_price': oldPriceCtrl.text.trim(),
      'discount_percent': discountPercentCtrl.text.trim(),
      'offer_start_date': offerStartDateCtrl.text.trim().isEmpty
          ? null
          : offerStartDateCtrl.text.trim(),
      'offer_end_date': offerEndDateCtrl.text.trim().isEmpty
          ? null
          : offerEndDateCtrl.text.trim(),
      'is_available': isAvailable,

      // حالة السيارة + المخزون
      'car_status': carStatusValue,
      'condition_status': conditionStatusValue,
      'vin': vinCtrl.text.trim(),
      'plate_number': plateNumberCtrl.text.trim(),
      'location': locationCtrl.text.trim(),
      'arrival_date': arrivalDateCtrl.text.trim().isEmpty
          ? null
          : arrivalDateCtrl.text.trim(),

      // مواصفات إضافية مرنة، مقسّمة حسب القسم اللي أضيفت فيه
      'extra_specs': () {
        final grouped = <String, Map<String, String>>{};
        for (final entry in extraSpecEntries) {
          final k = entry.keyCtrl.text.trim();
          final v = entry.valueCtrl.text.trim();
          if (k.isEmpty) continue;
          grouped.putIfAbsent(entry.category, () => {});
          grouped[entry.category]![k] = v;
        }
        // الـ40 بند المنظّمة من car_specs_schema.dart — كل واحد
        // بيتحط تحت القسم بتاعه الصحيح تلقائيًا
        structuredSpecValues.forEach((key, value) {
          if (value.trim().isEmpty) return;
          final categoryKey = findCarSpecCategoryKey(key);
          if (categoryKey == null) return;
          grouped.putIfAbsent(categoryKey, () => {});
          grouped[categoryKey]![key] = value;
        });
        return grouped;
      }(),
    };

    try {
      int carId;

      if (isEditing) {
        carId = widget.existingCar!['id'] as int;
        await Supabase.instance.client
            .from('cars')
            .update(data)
            .eq('id', carId);
      } else {
        final inserted = await Supabase.instance.client
            .from('cars')
            .insert(data)
            .select()
            .single();
        carId = inserted['id'] as int;
      }

      // نمسح الألوان والصور القديمة المرتبطة بالسيارة دي ونسجل الجديدة
      // (أسهل وأضمن من إننا نحاول نقارن الفرق واحد واحد)
      await Supabase.instance.client
          .from('car_color_availability')
          .delete()
          .eq('car_id', carId);

      if (selectedColorIds.isNotEmpty) {
        await Supabase.instance.client.from('car_color_availability').insert(
              selectedColorIds.map((colorId) {
                final exteriorUrls = (colorExteriorImageControllers[colorId] ??
                        [])
                    .map((c) => c.text.trim())
                    .where((url) => url.isNotEmpty)
                    .toList();
                final interiorUrls = (colorInteriorImageControllers[colorId] ??
                        [])
                    .map((c) => c.text.trim())
                    .where((url) => url.isNotEmpty)
                    .toList();

                return {
                  'car_id': carId,
                  'color_id': colorId,
                  'is_available': true,
                  // نسيب "image" (القديمة) بأول صورة خارجية عشان أي كود
                  // قديم لسه بيعتمد عليها يفضل شغال
                  'image': exteriorUrls.isNotEmpty ? exteriorUrls.first : '',
                  'exterior_images': exteriorUrls,
                  'interior_images': interiorUrls,
                };
              }).toList(),
            );
      }

      await Supabase.instance.client
          .from('car_images')
          .delete()
          .eq('car_id', carId);

      final extraImageUrls = extraImageControllers
          .map((c) => c.text.trim())
          .where((url) => url.isNotEmpty)
          .toSet() // يشيل أي تكرار في نفس القايمة قبل الحفظ
          .toList();

      if (extraImageUrls.isNotEmpty) {
        await Supabase.instance.client.from('car_images').upsert(
              extraImageUrls
                  .map((url) => {'car_id': carId, 'image': url})
                  .toList(),
              onConflict: 'car_id,image',
              ignoreDuplicates: true,
            );
      }

      // ============================================================
      // إشعار تلقائي للزبائن (سيارة جديدة / عرض جديد)
      // ============================================================
      final carDisplayName =
          '${brandCtrl.text.trim()} ${nameCtrl.text.trim()}'.trim();
      try {
        if (isOffer && !wasOfferInitially) {
          // بقت عليها عرض دلوقتي (سواء سيارة جديدة أو قديمة اتحطلها خصم)
          await Supabase.instance.client.from('announcements').insert({
            'title': isArabic ? 'عرض جديد!' : 'New offer!',
            'body': isArabic
                ? 'في عرض جديد على $carDisplayName، شوفه دلوقتي.'
                : 'A new offer is live on $carDisplayName, check it out now.',
            'type': 'offer',
            'car_id': carId,
          });
        } else if (!isEditing) {
          // سيارة جديدة تمامًا من غير عرض
          await Supabase.instance.client.from('announcements').insert({
            'title': isArabic ? 'سيارة جديدة!' : 'New car!',
            'body': isArabic
                ? 'ضفنا $carDisplayName لمعرضنا، شوف تفاصيلها دلوقتي.'
                : 'We added $carDisplayName to our showroom, check it out now.',
            'type': 'car',
            'car_id': carId,
          });
        }
      } catch (e) {
        // إشعار فشل مش لازم يوقف حفظ السيارة نفسها
        debugPrint('AUTO_ONE_DEBUG: تعذّر إرسال إشعار السيارة: $e');
      }

      if (!mounted) return;

      // تسجيل النشاط: لو السعر اتغيّر، سجّل القديم والجديد بالتحديد
      if (isEditing) {
        final oldPrice =
            (widget.existingCar?['price'] ?? '').toString().trim();
        final newPrice = priceCtrl.text.trim();
        if (oldPrice.isNotEmpty && oldPrice != newPrice) {
          await logActivity(
            isArabic
                ? 'عدّل سعر ${nameCtrl.text.trim()}: من $oldPrice إلى $newPrice'
                : 'Changed price of ${nameCtrl.text.trim()}: from $oldPrice to $newPrice',
          );
        } else {
          await logActivity(
            isArabic
                ? 'عدّل بيانات السيارة: ${nameCtrl.text.trim()}'
                : 'Edited car: ${nameCtrl.text.trim()}',
          );
        }
      } else {
        await logActivity(
          isArabic
              ? 'أضاف سيارة جديدة: ${nameCtrl.text.trim()}'
              : 'Added new car: ${nameCtrl.text.trim()}',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('AUTO_ONE_DEBUG: car save error: $e');
      setState(() => isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'حصلت مشكلة، حاولي تاني' : 'Something went wrong',
          ),
        ),
      );
    }
  }

  // حقل تاريخ بتقويم بدل الكتابة اليدوية، عشان نضمن الصيغة الصحيحة
  // اللي قاعدة البيانات محتاجاها دايمًا (YYYY-MM-DD)
  Widget _dateField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onTap: () async {
          final initial =
              DateTime.tryParse(controller.text.trim()) ?? DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            final y = picked.year.toString().padLeft(4, '0');
            final m = picked.month.toString().padLeft(2, '0');
            final d = picked.day.toString().padLeft(2, '0');
            controller.text = '$y-$m-$d';
          }
        },
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor:
              enabled ? Colors.grey.shade100 : Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return isArabic ? 'الحقل ده مطلوب' : 'This field is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(
            isEditing
                ? (isArabic ? 'تعديل السيارة' : 'Edit Car')
                : (isArabic ? 'سيارة جديدة' : 'New Car'),
          ),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _field(
                controller: nameCtrl,
                label: isArabic ? 'اسم السيارة' : 'Car name',
                required: true,
              ),
              _field(
                controller: nameEnCtrl,
                label: isArabic
                    ? 'اسم السيارة بالإنجليزي (اختياري)'
                    : 'Car name in English (optional)',
              ),
              _field(
                controller: brandCtrl,
                label: isArabic ? 'الماركة' : 'Brand',
                required: true,
                enabled: widget.lockedBrand == null,
              ),
              if (widget.lockedBrand != null) ...[
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? 'الماركة محدّدة أوتوماتيك لأنك بتضيف السيارة دي من جوه صفحة "${widget.lockedBrand}"'
                      : 'Brand is set automatically because you\'re adding this car from the "${widget.lockedBrand}" page',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              if (widget.lockedBrand == null && allBrands.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? 'دوس على الماركة عشان تتأكد إن الاسم مطابق بالظبط (بيمنع مشكلة "السيارة مش بتظهر" لما تدوس على الماركة في الموقع)'
                      : 'Tap a brand to make sure the name matches exactly',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allBrands.map((b) {
                    final nameEn = (b['name_en'] ?? '').toString();
                    final nameAr = (b['name_ar'] ?? '').toString();
                    final value = nameEn.isNotEmpty ? nameEn : nameAr;
                    if (value.isEmpty) return const SizedBox.shrink();
                    final isSelected =
                        brandCtrl.text.trim().toLowerCase() ==
                            value.toLowerCase();

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          brandCtrl.text = value;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.red
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isArabic && nameAr.isNotEmpty ? nameAr : value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                isArabic ? 'نوع السيارة' : 'Body type',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _bodyTypeChip('SUV', isArabic ? 'إس يو في' : 'SUV'),
                  _bodyTypeChip('SEDAN', isArabic ? 'سيدان' : 'Sedan'),
                  _bodyTypeChip('JEEP', isArabic ? 'جيب' : 'Jeep'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: yearCtrl,
                      label: isArabic ? 'السنة' : 'Year',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: priceCtrl,
                      label: isArabic ? 'السعر' : 'Price',
                      required: true,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      controller: imageCtrl,
                      label: isArabic
                          ? 'رابط الصورة الأساسية'
                          : 'Main image link',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed:
                          _isUploadingImage
                              ? null
                              : () => _pickAndUploadImage(imageCtrl),
                      icon: _isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        isArabic ? 'اختيار من الجهاز' : 'Browse',
                      ),
                    ),
                  ),
                ],
              ),
              if (imageCtrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: carImageAdaptive(
                        imageCtrl.text.trim(),
                        fit: BoxFit.cover,
                        showWatermark: false,
                      ),
                    ),
                  ),
                ),
              _field(
                controller: descriptionCtrl,
                label: isArabic ? 'الوصف' : 'Description',
                maxLines: 3,
              ),
              _field(
                controller: descriptionEnCtrl,
                label: isArabic
                    ? 'الوصف بالإنجليزي (اختياري)'
                    : 'Description in English (optional)',
                maxLines: 3,
              ),
              // ==========================================
              // SPECS — انتقل كل حاجة للصفحة الموحّدة (زرار
              // "المواصفات التفصيلية" في آخر الفورم)
              // ==========================================

              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              // ==========================================
              // COLORS — زرار صغير يفتح نافذة إدارة الألوان
              // ==========================================
              InkWell(
                onTap: _openColorsDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.palette_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isArabic ? 'إدارة الألوان' : 'Manage colors',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (selectedColorIds.isNotEmpty) ...[
                        SizedBox(
                          height: 22,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: selectedColorIds.take(5).map((id) {
                              final c = allColors.firstWhere(
                                (e) => e['id'] == id,
                                orElse: () => {},
                              );
                              final rawValue =
                                  (c['color_value'] as int?) ?? 0xFFFFFF;
                              return Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 4,
                                ),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF000000 | rawValue),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${selectedColorIds.length}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ] else
                        Text(
                          isArabic ? 'مفيش ألوان' : 'None',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              // ==========================================
              // GALLERY — زرار صغير يفتح نافذة إدارة صور المعرض
              // ==========================================
              InkWell(
                onTap: _openGalleryDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'إدارة صور المعرض'
                              : 'Manage gallery photos',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (extraImageControllers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${extraImageControllers.length}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SwitchListTile(
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  isArabic ? 'متاحة للعرض' : 'Available',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                value: isAvailable,
                activeColor: Colors.green,
                onChanged: (value) {
                  setState(() => isAvailable = value);
                },
              ),

              const SizedBox(height: 10),

              SwitchListTile(
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  isArabic ? 'عرض خاص / خصم' : 'Special Offer',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                value: isOffer,
                activeColor: Colors.red,
                onChanged: (value) {
                  setState(() => isOffer = value);
                },
              ),

              const SizedBox(height: 10),

              SwitchListTile(
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  isArabic ? 'سيارة مميزة (Featured)' : 'Featured car',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                value: isFeatured,
                activeColor: Colors.amber.shade800,
                onChanged: (value) {
                  setState(() => isFeatured = value);
                },
              ),

              if (isOffer) ...[
                const SizedBox(height: 10),
                _field(
                  controller: oldPriceCtrl,
                  label: isArabic
                      ? 'السعر القديم (قبل الخصم)'
                      : 'Old price (before discount)',
                ),
                _field(
                  controller: discountPercentCtrl,
                  label: isArabic
                      ? 'نسبة الخصم % (اختياري)'
                      : 'Discount % (optional)',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        controller: offerStartDateCtrl,
                        label: isArabic ? 'بداية العرض' : 'Start date',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateField(
                        controller: offerEndDateCtrl,
                        label: isArabic ? 'نهاية العرض' : 'End date',
                      ),
                    ),
                  ],
                ),
                Text(
                  isArabic
                      ? 'لو حددت تاريخ نهاية، العرض هيختفي أوتوماتيك من الموقع بعد التاريخ ده من غير ما تعمل حاجة.'
                      : 'If you set an end date, the offer disappears from the site automatically after that date.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],

              const SizedBox(height: 24),
              Text(
                isArabic ? 'الحالة والمخزون' : 'Status & Inventory',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonFormField<String>(
                  value: carStatusValue,
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text(isArabic ? 'متاحة' : 'Available'),
                    ),
                    DropdownMenuItem(
                      value: 'reserved',
                      child: Text(isArabic ? 'محجوزة' : 'Reserved'),
                    ),
                    DropdownMenuItem(
                      value: 'sold',
                      child: Text(isArabic ? 'مباعة' : 'Sold'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => carStatusValue = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonFormField<String>(
                  value: conditionStatusValue,
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: [
                    DropdownMenuItem(
                      value: 'new',
                      child: Text(isArabic ? 'جديدة' : 'New'),
                    ),
                    DropdownMenuItem(
                      value: 'used',
                      child: Text(isArabic ? 'مستعملة' : 'Used'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => conditionStatusValue = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),

              _field(
                controller: vinCtrl,
                label: isArabic ? 'رقم الشاصي (VIN)' : 'VIN',
              ),
              _field(
                controller: plateNumberCtrl,
                label: isArabic ? 'رقم اللوحة' : 'Plate number',
              ),
              _field(
                controller: locationCtrl,
                label: isArabic ? 'الموقع / المدينة' : 'Location',
              ),
              _dateField(
                controller: arrivalDateCtrl,
                label: isArabic ? 'تاريخ الوصول' : 'Arrival date',
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context)
                        .push<Map<String, String>>(
                      smoothRoute(
                        CarSpecsEditorPage(
                          isArabic: isArabic,
                          initialValues: structuredSpecValues,
                          engineCtrl: engineCtrl,
                          lengthCtrl: lengthCtrl,
                          widthCtrl: widthCtrl,
                          heightCtrl: heightCtrl,
                          wheelbaseCtrl: wheelbaseCtrl,
                          trunkCapacityCtrl: trunkCapacityCtrl,
                          horsepowerCtrl: horsepowerCtrl,
                          torqueCtrl: torqueCtrl,
                          fuelTankCtrl: fuelTankCtrl,
                          fuelConsumptionCtrl: fuelConsumptionCtrl,
                          infotainmentCtrl: infotainmentCtrl,
                          extraSpecEntries: extraSpecEntries,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        structuredSpecValues = result;
                        // البنود اللي قيمتها بترجع تتخزن في عمود
                        // حقيقي (مش extra_specs) — بنزامن القيمة مع
                        // الكنترولر بتاعها، عشان دالة الحفظ العادية
                        // تلتقطها زي ما هي من غير ما نلمسها.
                        void syncColumn(
                          String key,
                          TextEditingController ctrl, {
                          bool isToggle = false,
                        }) {
                          final value = result[key];
                          if (isToggle) {
                            ctrl.text = value != null ? 'نعم' : '';
                          } else {
                            ctrl.text = value ?? '';
                          }
                        }

                        syncColumn('fuel', fuelCtrl);
                        syncColumn('transmission', transmissionCtrl);
                        syncColumn('drive', driveCtrl);
                        syncColumn('seats', seatsCtrl);
                        syncColumn('sunroof', sunroofCtrl);
                        syncColumn('airbags', airbagsCtrl);
                        syncColumn(
                          'wireless_charger',
                          wirelessChargerCtrl,
                          isToggle: true,
                        );
                        syncColumn(
                          'abs_system',
                          absSystemCtrl,
                          isToggle: true,
                        );
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                  icon: const Icon(Icons.checklist_rounded),
                  label: Text(
                    structuredSpecValues.isEmpty
                        ? (isArabic ? 'إضافة المواصفات' : 'Add specifications')
                        : (isArabic
                            ? 'تعديل المواصفات (${structuredSpecValues.length})'
                            : 'Edit specifications (${structuredSpecValues.length})'),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isArabic ? 'حفظ' : 'Save',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// STRUCTURED SPEC ITEM TILE (بند واحد: مفتاح تشغيل + اختيارات)
// ============================================================
class _StructuredSpecItemTile extends StatelessWidget {
  final CarSpecItem item;
  final bool isArabic;
  final String? currentValue; // null = مش متوفرة في السيارة دي
  final void Function(String? value) onChanged;
  final Color accentColor;

  const _StructuredSpecItemTile({
    required this.item,
    required this.isArabic,
    required this.currentValue,
    required this.onChanged,
    this.accentColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = currentValue != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 17, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? item.labelAr : item.labelEn,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                activeColor: accentColor,
                onChanged: (value) {
                  if (!value) {
                    onChanged(null);
                    return;
                  }
                  // بنفعّل البند: لو toggle، القيمة نفسها 'true'. لو
                  // choice/multiChoice، بنبدأ باختيار أول قيمة تلقائيًا
                  // عشان يبقى فيه قيمة صالحة على طول.
                  if (item.type == CarSpecType.toggle) {
                    onChanged('true');
                  } else if (item.options.isNotEmpty) {
                    onChanged(item.options.first.value);
                  } else {
                    onChanged('true');
                  }
                },
              ),
            ],
          ),
          if (isEnabled && item.type != CarSpecType.toggle) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.options.map((option) {
                final baseLabel = isArabic ? option.labelAr : option.labelEn;
                final unit = isArabic ? item.unitAr : item.unitEn;
                final displayLabel =
                    (unit != null && unit.isNotEmpty && item.type == CarSpecType.choice)
                        ? '$baseLabel $unit'
                        : baseLabel;

                final selectedSet = (currentValue ?? '')
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toSet();

                final isSelected = item.type == CarSpecType.choice
                    ? currentValue == option.value
                    : selectedSet.contains(option.value);

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    if (item.type == CarSpecType.choice) {
                      onChanged(option.value);
                      return;
                    }
                    // multiChoice: نضيف/نشيل القيمة دي من القايمة
                    final updated = {...selectedSet};
                    if (updated.contains(option.value)) {
                      updated.remove(option.value);
                    } else {
                      updated.add(option.value);
                    }
                    // لو اتشالت كل الاختيارات، نقفل البند تلقائيًا
                    onChanged(updated.isEmpty ? null : updated.join(','));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.black12,
                      ),
                    ),
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// CAR SPECS EDITOR PAGE (صفحة منفصلة لكل الـ40 بند، قايمة واحدة
// مسطّحة من غير تقسيم لأقسام) — بتفتح بزرار من فورم السيارة، وبترجع
// القيم المحدّثة لما تتقفل، من غير ما تحفظ في قاعدة البيانات
// مباشرة (الحفظ الفعلي بيحصل مع باقي بيانات السيارة سوا).
// ============================================================
class CarSpecsEditorPage extends StatefulWidget {
  final bool isArabic;
  final Map<String, String> initialValues;
  // البنود الحرة القديمة (أرقام ووصف)، بتتعدّل مباشرة على نفس
  // الكنترولرز اللي الفورم الأساسي شايلها، فمحتاجش نرجّع قيمتها
  // زي structuredSpecValues.
  final TextEditingController engineCtrl;
  final TextEditingController lengthCtrl;
  final TextEditingController widthCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController wheelbaseCtrl;
  final TextEditingController trunkCapacityCtrl;
  final TextEditingController horsepowerCtrl;
  final TextEditingController torqueCtrl;
  final TextEditingController fuelTankCtrl;
  final TextEditingController fuelConsumptionCtrl;
  final TextEditingController infotainmentCtrl;
  // مواصفات مخصّصة حرة (اسم + قيمة)، برضو بتتعدّل مباشرة على نفس
  // القايمة اللي الفورم الأساسي شايلها.
  final List<ExtraSpecEntry> extraSpecEntries;

  const CarSpecsEditorPage({
    super.key,
    required this.isArabic,
    required this.initialValues,
    required this.engineCtrl,
    required this.lengthCtrl,
    required this.widthCtrl,
    required this.heightCtrl,
    required this.wheelbaseCtrl,
    required this.trunkCapacityCtrl,
    required this.horsepowerCtrl,
    required this.torqueCtrl,
    required this.fuelTankCtrl,
    required this.fuelConsumptionCtrl,
    required this.infotainmentCtrl,
    required this.extraSpecEntries,
  });

  @override
  State<CarSpecsEditorPage> createState() => _CarSpecsEditorPageState();
}

class _CarSpecsEditorPageState extends State<CarSpecsEditorPage> {
  late Map<String, String> values;
  // "info" قسم افتراضي إضافي (مش من ضمن الشيما) للمعلومات الحرة
  static const String _freeTextCategoryKey = 'free_text_info';
  String selectedCategoryKey = carSpecCategories.first.key;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    values = Map<String, String>.from(widget.initialValues);
  }

  int _activeCountFor(CarSpecCategory category) =>
      category.items.where((item) => values.containsKey(item.key)).length;

  void _onItemChanged(String key, String? value) {
    setState(() {
      if (value == null) {
        values.remove(key);
      } else {
        values[key] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'المواصفات' : 'Specifications'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(values),
              child: Text(
                isArabic ? 'تم' : 'Done',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return isWide ? _buildWideLayout() : _buildNarrowLayout();
          },
        ),
      ),
    );
  }

  // ==========================================================
  // الديسكتوب: عمود قائمة (يمين) + عمود تفاصيل (المساحة الباقية)
  // ==========================================================
  Widget _buildWideLayout() {
    final isFreeTextSelected = selectedCategoryKey == _freeTextCategoryKey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 280,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (final category in carSpecCategories)
                _CategoryNavRow(
                  category: category,
                  isArabic: isArabic,
                  isSelected: category.key == selectedCategoryKey,
                  activeCount: _activeCountFor(category),
                  onTap: () =>
                      setState(() => selectedCategoryKey = category.key),
                ),
              _FreeTextNavRow(
                isArabic: isArabic,
                isSelected: isFreeTextSelected,
                onTap: () =>
                    setState(() => selectedCategoryKey = _freeTextCategoryKey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              key: ValueKey(selectedCategoryKey),
              child: isFreeTextSelected
                  ? _FreeTextInfoPanel(
                      isArabic: isArabic,
                      engineCtrl: widget.engineCtrl,
                      lengthCtrl: widget.lengthCtrl,
                      widthCtrl: widget.widthCtrl,
                      heightCtrl: widget.heightCtrl,
                      wheelbaseCtrl: widget.wheelbaseCtrl,
                      trunkCapacityCtrl: widget.trunkCapacityCtrl,
                      horsepowerCtrl: widget.horsepowerCtrl,
                      torqueCtrl: widget.torqueCtrl,
                      fuelTankCtrl: widget.fuelTankCtrl,
                      fuelConsumptionCtrl: widget.fuelConsumptionCtrl,
                      infotainmentCtrl: widget.infotainmentCtrl,
                      extraSpecEntries: widget.extraSpecEntries,
                      onExtrasChanged: () => setState(() {}),
                    )
                  : _CategoryDetailPanel(
                      category: carSpecCategories
                          .firstWhere((c) => c.key == selectedCategoryKey),
                      isArabic: isArabic,
                      values: values,
                      onItemChanged: _onItemChanged,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // الموبايل: أكورديون رأسي، قسم واحد بس مفتوح في نفس الوقت
  // ==========================================================
  Widget _buildNarrowLayout() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        for (final category in carSpecCategories)
          _MobileAccordionSection(
            category: category,
            isArabic: isArabic,
            values: values,
            isOpen: category.key == selectedCategoryKey,
            activeCount: _activeCountFor(category),
            onHeaderTap: () {
              setState(() {
                selectedCategoryKey =
                    selectedCategoryKey == category.key ? '' : category.key;
              });
            },
            onItemChanged: _onItemChanged,
          ),
        _MobileFreeTextAccordionSection(
          isArabic: isArabic,
          isOpen: selectedCategoryKey == _freeTextCategoryKey,
          onHeaderTap: () {
            setState(() {
              selectedCategoryKey = selectedCategoryKey == _freeTextCategoryKey
                  ? ''
                  : _freeTextCategoryKey;
            });
          },
          engineCtrl: widget.engineCtrl,
          lengthCtrl: widget.lengthCtrl,
          widthCtrl: widget.widthCtrl,
          heightCtrl: widget.heightCtrl,
          wheelbaseCtrl: widget.wheelbaseCtrl,
          trunkCapacityCtrl: widget.trunkCapacityCtrl,
          horsepowerCtrl: widget.horsepowerCtrl,
          torqueCtrl: widget.torqueCtrl,
          fuelTankCtrl: widget.fuelTankCtrl,
          fuelConsumptionCtrl: widget.fuelConsumptionCtrl,
          infotainmentCtrl: widget.infotainmentCtrl,
          extraSpecEntries: widget.extraSpecEntries,
          onExtrasChanged: () => setState(() {}),
        ),
      ],
    );
  }
}

// ============================================================
// CATEGORY NAV ROW (صف واحد في القايمة الجانبية على الديسكتوب)
// ============================================================
class _CategoryNavRow extends StatelessWidget {
  final CarSpecCategory category;
  final bool isArabic;
  final bool isSelected;
  final int activeCount;
  final VoidCallback onTap;

  const _CategoryNavRow({
    required this.category,
    required this.isArabic,
    required this.isSelected,
    required this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = category.items.length;
    final ratio = total == 0 ? 0.0 : activeCount / total;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? category.color : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            _MiniProgressRing(
              ratio: ratio,
              color: category.color,
              icon: category.icon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? category.labelAr : category.labelEn,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? category.color : Colors.black87,
                    ),
                  ),
                  Text(
                    isArabic
                        ? '$activeCount من $total مفعّلة'
                        : '$activeCount of $total active',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isArabic
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: isSelected ? category.color : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MINI PROGRESS RING (دايرة تقدم صغيرة بأيقونة القسم جوّاها)
// ============================================================
class _MiniProgressRing extends StatelessWidget {
  final double ratio;
  final Color color;
  final IconData icon;

  const _MiniProgressRing({
    required this.ratio,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              value: ratio == 0 ? 1 : ratio,
              strokeWidth: 3,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio == 0 ? Colors.transparent : color,
              ),
            ),
          ),
          Icon(icon, size: 15, color: color),
        ],
      ),
    );
  }
}

// ============================================================
// CATEGORY DETAIL PANEL (محتوى القسم المختار على الديسكتوب)
// ============================================================
class _CategoryDetailPanel extends StatelessWidget {
  final CarSpecCategory category;
  final bool isArabic;
  final Map<String, String> values;
  final void Function(String key, String? value) onItemChanged;

  const _CategoryDetailPanel({
    required this.category,
    required this.isArabic,
    required this.values,
    required this.onItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: category.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, color: category.color, size: 22),
              const SizedBox(width: 8),
              Text(
                isArabic ? category.labelAr : category.labelEn,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 2, color: category.color.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          for (var i = 0; i < category.items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _StructuredSpecItemTile(
                item: category.items[i],
                isArabic: isArabic,
                currentValue: values[category.items[i].key],
                accentColor: category.color,
                onChanged: (value) =>
                    onItemChanged(category.items[i].key, value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// MOBILE ACCORDION SECTION (قسم واحد في الأكورديون الرأسي)
// ============================================================
class _MobileAccordionSection extends StatelessWidget {
  final CarSpecCategory category;
  final bool isArabic;
  final Map<String, String> values;
  final bool isOpen;
  final int activeCount;
  final VoidCallback onHeaderTap;
  final void Function(String key, String? value) onItemChanged;

  const _MobileAccordionSection({
    required this.category,
    required this.isArabic,
    required this.values,
    required this.isOpen,
    required this.activeCount,
    required this.onHeaderTap,
    required this.onItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = category.items.length;
    final ratio = total == 0 ? 0.0 : activeCount / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? category.color.withValues(alpha: 0.35)
              : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _MiniProgressRing(
                    ratio: ratio,
                    color: category.color,
                    icon: category.icon,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? category.labelAr : category.labelEn,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          isArabic
                              ? '$activeCount من $total مفعّلة'
                              : '$activeCount of $total active',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: isOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          color: Colors.black12,
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                        for (final item in category.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: _StructuredSpecItemTile(
                              item: item,
                              isArabic: isArabic,
                              currentValue: values[item.key],
                              accentColor: category.color,
                              onChanged: (value) =>
                                  onItemChanged(item.key, value),
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FREE TEXT NAV ROW (صف "معلومات إضافية" في القايمة الجانبية)
// ============================================================
class _FreeTextNavRow extends StatelessWidget {
  final bool isArabic;
  final bool isSelected;
  final VoidCallback onTap;

  const _FreeTextNavRow({
    required this.isArabic,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.grey.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.grey.shade600 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notes_rounded,
              size: 20,
              color: isSelected ? Colors.grey.shade800 : Colors.black45,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isArabic ? 'معلومات إضافية' : 'Additional info',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.grey.shade800 : Colors.black87,
                ),
              ),
            ),
            Icon(
              isArabic
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FREE TEXT INFO PANEL (المحرك، الأبعاد، القوة، ومواصفات مخصّصة
// حرة — نص عادي، مش مفتاح+اختيارات، لأن قيمتها مختلفة كل سيارة)
// ============================================================
class _FreeTextInfoPanel extends StatelessWidget {
  final bool isArabic;
  final TextEditingController engineCtrl;
  final TextEditingController lengthCtrl;
  final TextEditingController widthCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController wheelbaseCtrl;
  final TextEditingController trunkCapacityCtrl;
  final TextEditingController horsepowerCtrl;
  final TextEditingController torqueCtrl;
  final TextEditingController fuelTankCtrl;
  final TextEditingController fuelConsumptionCtrl;
  final TextEditingController infotainmentCtrl;
  final List<ExtraSpecEntry> extraSpecEntries;
  final VoidCallback onExtrasChanged;

  const _FreeTextInfoPanel({
    required this.isArabic,
    required this.engineCtrl,
    required this.lengthCtrl,
    required this.widthCtrl,
    required this.heightCtrl,
    required this.wheelbaseCtrl,
    required this.trunkCapacityCtrl,
    required this.horsepowerCtrl,
    required this.torqueCtrl,
    required this.fuelTankCtrl,
    required this.fuelConsumptionCtrl,
    required this.infotainmentCtrl,
    required this.extraSpecEntries,
    required this.onExtrasChanged,
  });

  Widget _textField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: Colors.grey.shade700, size: 22),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'معلومات إضافية' : 'Additional info',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'قيمها مختلفة لكل سيارة (أرقام أو وصف حر)، فبتتكتب يدوي بدل الاختيار من قايمة.'
                : 'Values vary per car, so these are typed manually instead of picked from a list.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          _textField(engineCtrl, isArabic ? 'المحرك' : 'Engine'),
          Row(
            children: [
              Expanded(
                child: _textField(
                  lengthCtrl,
                  isArabic ? 'الطول (سم)' : 'Length (cm)',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _textField(
                  widthCtrl,
                  isArabic ? 'العرض (سم)' : 'Width (cm)',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _textField(
                  heightCtrl,
                  isArabic ? 'الارتفاع (سم)' : 'Height (cm)',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _textField(
                  wheelbaseCtrl,
                  isArabic ? 'قاعدة العجلات' : 'Wheelbase',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _textField(
                  trunkCapacityCtrl,
                  isArabic ? 'سعة صندوق الأمتعة' : 'Trunk capacity',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _textField(
                  horsepowerCtrl,
                  isArabic ? 'قوة المحرك (حصان)' : 'Horsepower',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _textField(
                  torqueCtrl,
                  isArabic ? 'عزم الدوران' : 'Torque',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _textField(
                  fuelTankCtrl,
                  isArabic ? 'سعة خزان الوقود' : 'Fuel tank capacity',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _textField(
                  fuelConsumptionCtrl,
                  isArabic ? 'استهلاك الوقود' : 'Fuel consumption',
                ),
              ),
            ],
          ),
          _textField(
            infotainmentCtrl,
            isArabic ? 'نظام الترفيه/الشاشة (وصف حر)' : 'Infotainment',
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'مواصفات مخصّصة' : 'Custom specs',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          for (final entry in extraSpecEntries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: entry.keyCtrl,
                      decoration: InputDecoration(
                        hintText: isArabic ? 'اسم المواصفة' : 'Spec name',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: entry.valueCtrl,
                      decoration: InputDecoration(
                        hintText: isArabic ? 'القيمة' : 'Value',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      entry.keyCtrl.dispose();
                      entry.valueCtrl.dispose();
                      extraSpecEntries.remove(entry);
                      onExtrasChanged();
                    },
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () {
                extraSpecEntries.add(
                  ExtraSpecEntry(
                    category: 'other',
                    keyCtrl: TextEditingController(),
                    valueCtrl: TextEditingController(),
                  ),
                );
                onExtrasChanged();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(isArabic ? 'إضافة مواصفة' : 'Add spec'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MOBILE FREE TEXT ACCORDION SECTION
// ============================================================
class _MobileFreeTextAccordionSection extends StatelessWidget {
  final bool isArabic;
  final bool isOpen;
  final VoidCallback onHeaderTap;
  final TextEditingController engineCtrl;
  final TextEditingController lengthCtrl;
  final TextEditingController widthCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController wheelbaseCtrl;
  final TextEditingController trunkCapacityCtrl;
  final TextEditingController horsepowerCtrl;
  final TextEditingController torqueCtrl;
  final TextEditingController fuelTankCtrl;
  final TextEditingController fuelConsumptionCtrl;
  final TextEditingController infotainmentCtrl;
  final List<ExtraSpecEntry> extraSpecEntries;
  final VoidCallback onExtrasChanged;

  const _MobileFreeTextAccordionSection({
    required this.isArabic,
    required this.isOpen,
    required this.onHeaderTap,
    required this.engineCtrl,
    required this.lengthCtrl,
    required this.widthCtrl,
    required this.heightCtrl,
    required this.wheelbaseCtrl,
    required this.trunkCapacityCtrl,
    required this.horsepowerCtrl,
    required this.torqueCtrl,
    required this.fuelTankCtrl,
    required this.fuelConsumptionCtrl,
    required this.infotainmentCtrl,
    required this.extraSpecEntries,
    required this.onExtrasChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen ? Colors.grey.shade600 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.notes_rounded, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic ? 'معلومات إضافية' : 'Additional info',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: isOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: _FreeTextInfoPanel(
                      isArabic: isArabic,
                      engineCtrl: engineCtrl,
                      lengthCtrl: lengthCtrl,
                      widthCtrl: widthCtrl,
                      heightCtrl: heightCtrl,
                      wheelbaseCtrl: wheelbaseCtrl,
                      trunkCapacityCtrl: trunkCapacityCtrl,
                      horsepowerCtrl: horsepowerCtrl,
                      torqueCtrl: torqueCtrl,
                      fuelTankCtrl: fuelTankCtrl,
                      fuelConsumptionCtrl: fuelConsumptionCtrl,
                      infotainmentCtrl: infotainmentCtrl,
                      extraSpecEntries: extraSpecEntries,
                      onExtrasChanged: onExtrasChanged,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
