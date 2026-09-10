import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';
import '../admin/admin_shared.dart';

// ============================================================
// ADMIN INVENTORY (CARS CRUD)
// ============================================================
class AdminCarsPage extends StatefulWidget {
  final bool isArabic;

  const AdminCarsPage({super.key, required this.isArabic});

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
      final response = await Supabase.instance.client
          .from('cars')
          .select(
            'id, brand, name, price, year, image, is_available, car_status, sort_order',
          )
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
      await Supabase.instance.client.from('cars').delete().eq('id', id);
      await logActivity(
        isArabic
            ? 'حذف السيارة: ${carName ?? id}'
            : 'Deleted car: ${carName ?? id}',
      );
      _loadCars();
    } catch (e) {
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
                        isArabic
                            ? 'مفيش سيارات في المخزون لسه'
                            : 'No cars in inventory yet',
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

  const CarFormPage({
    super.key,
    required this.isArabic,
    this.existingCar,
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

  // مواصفات إضافية مرنة (Key : Value)
  List<MapEntry<TextEditingController, TextEditingController>>
      extraSpecControllers = [];

  // الألوان المتاحة في المتجر كله، وإيه اللي متحدد للسيارة دي
  List<Map<String, dynamic>> allColors = [];
  Set<int> selectedColorIds = {};
  // رابط صورة خاص بكل لون متحدد (لو موجود)
  Map<int, TextEditingController> colorImageControllers = {};
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
    brandCtrl = TextEditingController(text: car?['brand']?.toString() ?? '');
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
      rawExtraSpecs.forEach((key, value) {
        extraSpecControllers.add(
          MapEntry(
            TextEditingController(text: key.toString()),
            TextEditingController(text: value.toString()),
          ),
        );
      });
    }

    _loadExtras();
  }

  // بيجيب كل الألوان المتاحة، وألوان/صور السيارة دي لو بنعدّل
  Future<void> _loadExtras() async {
    try {
      final colorsResponse =
          await Supabase.instance.client.from('colors').select();
      allColors = List<Map<String, dynamic>>.from(colorsResponse as List);

      if (isEditing) {
        final carId = widget.existingCar!['id'] as int;

        final carColorsResponse = await Supabase.instance.client
            .from('car_color_availability')
            .select('color_id, image')
            .eq('car_id', carId)
            .eq('is_available', true);

        selectedColorIds = (carColorsResponse as List)
            .map((row) => row['color_id'] as int)
            .toSet();

        for (final row in carColorsResponse) {
          final colorId = row['color_id'] as int;
          colorImageControllers[colorId] = TextEditingController(
            text: (row['image'] ?? '').toString(),
          );
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
  // في خانة رابط الصورة.
  Future<void> _pickAndUploadImage() async {
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
        final bytes = reader.result as Uint8List;

        final brandFolder = brandCtrl.text.trim().isEmpty
            ? 'other'
            : brandCtrl.text.trim().toLowerCase();
        final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final path =
            '$brandFolder/${DateTime.now().millisecondsSinceEpoch}_$safeName';

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
            imageCtrl.text = publicUrl;
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
    for (final entry in extraSpecControllers) {
      entry.key.dispose();
      entry.value.dispose();
    }
    for (final controller in extraImageControllers) {
      controller.dispose();
    }
    for (final controller in colorImageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _openColorsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isArabic ? 'إدارة الألوان' : 'Manage colors'),
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
                                      colorImageControllers[colorId]
                                          ?.dispose();
                                      colorImageControllers.remove(colorId);
                                    } else {
                                      selectedColorIds.add(colorId);
                                      colorImageControllers.putIfAbsent(
                                        colorId,
                                        () => TextEditingController(),
                                      );
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

                          final controller = colorImageControllers
                              .putIfAbsent(colorId, () => TextEditingController());

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: displayColor,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.black12),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: isArabic
                                          ? 'رابط صورة اللون $name (اختياري)'
                                          : 'Image link for $name (optional)',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
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

      // مواصفات إضافية مرنة
      'extra_specs': {
        for (final entry in extraSpecControllers)
          if (entry.key.text.trim().isNotEmpty)
            entry.key.text.trim(): entry.value.text.trim(),
      },
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
              selectedColorIds
                  .map((colorId) => {
                        'car_id': carId,
                        'color_id': colorId,
                        'is_available': true,
                        'image': colorImageControllers[colorId]
                                ?.text
                                .trim() ??
                            '',
                      })
                  .toList(),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
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
              ),
              _field(
                controller: categoryCtrl,
                label: isArabic ? 'الفئة' : 'Category',
              ),
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
                          _isUploadingImage ? null : _pickAndUploadImage,
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
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: seatsCtrl,
                      label: isArabic ? 'المقاعد' : 'Seats',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: engineCtrl,
                      label: isArabic ? 'المحرك' : 'Engine',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: transmissionCtrl,
                      label: isArabic ? 'ناقل الحركة' : 'Transmission',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: fuelCtrl,
                      label: isArabic ? 'الوقود' : 'Fuel',
                    ),
                  ),
                ],
              ),
              _field(
                controller: driveCtrl,
                label: isArabic ? 'نظام الدفع' : 'Drive system',
              ),

              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: lengthCtrl,
                      label: isArabic ? 'الطول (سم)' : 'Length (cm)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: widthCtrl,
                      label: isArabic ? 'العرض (سم)' : 'Width (cm)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: heightCtrl,
                      label: isArabic ? 'الارتفاع (سم)' : 'Height (cm)',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: wheelbaseCtrl,
                      label: isArabic ? 'قاعدة العجلات' : 'Wheelbase',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: trunkCapacityCtrl,
                      label:
                          isArabic ? 'سعة صندوق الأمتعة' : 'Trunk capacity',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              Text(
                isArabic ? 'مواصفات إضافية للقيادة' : 'Extra driving specs',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: horsepowerCtrl,
                      label: isArabic ? 'قوة المحرك (حصان)' : 'Horsepower',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: torqueCtrl,
                      label: isArabic ? 'عزم الدوران' : 'Torque',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: fuelTankCtrl,
                      label:
                          isArabic ? 'سعة خزان الوقود' : 'Fuel tank capacity',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: fuelConsumptionCtrl,
                      label:
                          isArabic ? 'استهلاك الوقود' : 'Fuel consumption',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              Text(
                isArabic ? 'التجهيزات والمزايا' : 'Features',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: infotainmentCtrl,
                      label:
                          isArabic ? 'نظام الترفيه/الشاشة' : 'Infotainment',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: sunroofCtrl,
                      label: isArabic ? 'فتحة سقف' : 'Sunroof',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: cameraSensorsCtrl,
                      label: isArabic
                          ? 'كاميرا خلفية + حساسات ركن'
                          : 'Camera & sensors',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: wirelessChargerCtrl,
                      label:
                          isArabic ? 'شاحن لاسلكي' : 'Wireless charger',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),

              Text(
                isArabic ? 'الأمان' : 'Safety',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: airbagsCtrl,
                      label: isArabic
                          ? 'عدد الوسائد الهوائية'
                          : 'Number of airbags',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: absSystemCtrl,
                      label: isArabic ? 'نظام ABS' : 'ABS system',
                    ),
                  ),
                ],
              ),

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
                      setState(() {
                        extraImageControllers.add(TextEditingController());
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
                        onPressed: () {
                          setState(() {
                            controller.dispose();
                            extraImageControllers.remove(controller);
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

              const SizedBox(height: 10),
              Text(
                isArabic ? 'مواصفات إضافية' : 'Extra specs',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isArabic
                    ? 'ضيف أي مواصفة عايزها (زي ACC، تسخين المقاعد...) بالاسم والقيمة'
                    : 'Add any spec (e.g. ACC, Seat heating...) with a name and value',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),

              for (var i = 0; i < extraSpecControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: extraSpecControllers[i].key,
                          decoration: InputDecoration(
                            hintText: isArabic ? 'اسم المواصفة' : 'Spec name',
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
                          controller: extraSpecControllers[i].value,
                          decoration: InputDecoration(
                            hintText: isArabic ? 'القيمة' : 'Value',
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
                          setState(() {
                            extraSpecControllers.removeAt(i);
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

              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    extraSpecControllers.add(
                      MapEntry(
                        TextEditingController(),
                        TextEditingController(),
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  isArabic ? 'إضافة مواصفة' : 'Add spec',
                ),
              ),

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

