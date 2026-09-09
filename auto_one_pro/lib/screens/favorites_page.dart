import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/favorites_compare.dart';
import '../shared/repository.dart';
import '../screens/home_page.dart';

// ============================================================
// FAVORITES PAGE
// ============================================================
class FavoritesPage extends StatefulWidget {
  final bool isArabic;

  const FavoritesPage({super.key, required this.isArabic});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}


class _FavoritesPageState extends State<FavoritesPage> {
  bool get isArabic => widget.isArabic;

  @override
  Widget build(BuildContext context) {
    final favoriteCars =
        cars.where((c) => c.id != null && favoriteCarIds.contains(c.id)).toList();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f8),
        appBar: AppBar(
          backgroundColor: kHeaderColor,
          foregroundColor: kHeaderTextColor,
          title: Text(isArabic ? 'السيارات المفضلة' : 'Favorite Cars'),
        ),
        body: favoriteCars.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 60,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic
                          ? 'لسه مفيش سيارات في المفضلة'
                          : 'No favorite cars yet',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'دوسي على أيقونة ♡ في أي سيارة عشان تضيفيها هنا'
                          : 'Tap ♡ on any car to add it here',
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  mainAxisExtent: 420,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: favoriteCars.length,
                itemBuilder: (context, index) {
                  final car = favoriteCars[index];
                  return FeaturedCarCard(
                    key: ValueKey('${car.name}-${car.year}'),
                    car: car,
                    isArabic: isArabic,
                  );
                },
              ),
      ),
    );
  }
}

