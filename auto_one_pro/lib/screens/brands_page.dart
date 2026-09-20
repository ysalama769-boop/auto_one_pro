import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

// ============================================================
// BRANDS PAGE (كل الماركات - "موزّع معتمد لجميع السيارات")
// ============================================================
class BrandsPage extends StatefulWidget {
  final bool isArabic;
  final void Function(String brand) onBrandTap;

  const BrandsPage({
    super.key,
    required this.isArabic,
    required this.onBrandTap,
  });

  @override
  State<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends State<BrandsPage> {
  List<Map<String, dynamic>> brands = [];
  bool isLoading = true;

  bool get isArabic => widget.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await Supabase.instance.client
          .from('brands')
          .select()
          .eq('is_active', true)
          .order('name_ar');
      setState(() {
        brands = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'الماركات' : 'Brands'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1C1C1C), Color(0xFF0D0D0D)],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.red,
                      size: 38,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isArabic
                          ? 'موزّع معتمد لجميع السيارات'
                          : 'Authorized Distributor for All Brands',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isArabic
                          ? 'نفخر بكوننا موزّع معتمد لأفضل ماركات السيارات، بضمان الجودة والثقة.'
                          : 'We are proud to be an authorized distributor for the finest car brands, backed by quality and trust.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(),
                )
              else if (brands.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Text(
                    isArabic ? 'مفيش ماركات متاحة دلوقتي' : 'No brands available',
                    style: const TextStyle(color: Colors.black45),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 5
                          : constraints.maxWidth >= 600
                              ? 4
                              : 3;
                      final cardWidth =
                          (constraints.maxWidth - (columns - 1) * 16) / columns;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 20,
                        children: brands.map((b) {
                          final nameAr = (b['name_ar'] ?? '').toString();
                          final nameEn = (b['name_en'] ?? '').toString();
                          final name = isArabic
                              ? nameAr
                              : (nameEn.isEmpty ? nameAr : nameEn);
                          final logo = (b['logo'] ?? '').toString();
                          final matchKey =
                              nameEn.isNotEmpty ? nameEn : nameAr;

                          return SizedBox(
                            width: cardWidth,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: () => widget.onBrandTap(matchKey),
                              child: Column(
                                children: [
                                  Container(
                                    width: 88,
                                    height: 88,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white,
                                          Color(0xfffafafa),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red
                                              .withValues(alpha: 0.25),
                                          blurRadius: 20,
                                          spreadRadius: 1,
                                        ),
                                        const BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: logo.isEmpty
                                        ? const Icon(
                                            Icons.directions_car_filled_rounded,
                                            size: 32,
                                            color: Colors.red,
                                          )
                                        : carImageAdaptive(
                                            logo,
                                            fit: BoxFit.contain,
                                            showWatermark: false,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons
                                                    .directions_car_filled_rounded,
                                                size: 32,
                                                color: Colors.red,
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 30),
              AutoOneFooter(isArabic: isArabic),
            ],
          ),
        ),
      ),
    );
  }
}
