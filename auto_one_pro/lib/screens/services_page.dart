import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/constants.dart';
import '../shared/widgets.dart';

// ============================================================
// SERVICES PAGE (باقات الخدمات - صفحة مستقلة للزبائن)
// ============================================================
class ServicesPage extends StatefulWidget {
  final bool isArabic;
  const ServicesPage({super.key, required this.isArabic});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Map<String, dynamic>> packages = [];
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
          .from('service_packages')
          .select()
          .order('price_after');
      setState(() {
        packages = List<Map<String, dynamic>>.from(response as List);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          title: Text(isArabic ? 'الخدمات' : 'Services'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      isArabic ? 'باقاتنا وخدماتنا' : 'Our Packages & Services',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic
                          ? 'اختار الباقة اللي تناسبك من خدماتنا المتنوعة بأسعار مميزة.'
                          : 'Choose the package that suits you from our varied services at great prices.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(),
                )
              else if (packages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Text(
                    isArabic ? 'مفيش باقات متاحة دلوقتي' : 'No packages available yet',
                    style: const TextStyle(color: Colors.black45),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 4
                          : constraints.maxWidth >= 600
                              ? 2
                              : 1;
                      final cardWidth =
                          (constraints.maxWidth - (columns - 1) * 16) / columns;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: packages.map((p) {
                          final nameAr = (p['name_ar'] ?? '').toString();
                          final nameEn = (p['name_en'] ?? '').toString();
                          final name = isArabic
                              ? nameAr
                              : (nameEn.isEmpty ? nameAr : nameEn);
                          final desc = (p['description_ar'] ?? '').toString();
                          final priceBefore = p['price_before'];
                          final priceAfter = p['price_after'];
                          final pdf = (p['pdf_url'] ?? '').toString();

                          return SizedBox(
                            width: cardWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.black12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 14,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          name,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (priceBefore != null) ...[
                                              Text(
                                                '$priceBefore',
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Text(
                                              '$priceAfter',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(bottom: 3),
                                              child: Text(
                                                isArabic ? 'ر.س' : 'SAR',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        if (desc.isNotEmpty) ...[
                                          Text(
                                            desc,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Colors.black54,
                                              height: 1.6,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        SizedBox(
                                          width: double.infinity,
                                          child: pdf.isNotEmpty
                                              ? OutlinedButton.icon(
                                                  onPressed: () => _openPdf(pdf),
                                                  icon: const Icon(
                                                    Icons.picture_as_pdf_outlined,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    isArabic
                                                        ? 'تفاصيل الباقة (PDF)'
                                                        : 'Package details (PDF)',
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    side: const BorderSide(
                                                      color: Colors.red,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
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

              const SizedBox(height: 50),
              AutoOneFooter(isArabic: isArabic),
            ],
          ),
        ),
      ),
    );
  }
}
