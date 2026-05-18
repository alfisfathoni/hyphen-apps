import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const HypenApp());

const Color primaryBrown = Color(0xFF856A51);

class HypenApp extends StatelessWidget {
  const HypenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYPEN.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', 
      ),
      home: const CategoriesScreen(),
    );
  }
}

class CategoryItem {
  final String label;
  final String imagePath;
  final Color placeholderColor;

  const CategoryItem({
    required this.label,
    required this.imagePath,
    required this.placeholderColor,
  });
}

const List<CategoryItem> categories = [
  CategoryItem(
    label: 'WINTER\nOUTFITS',
    imagePath: 'assets/Winter.jpg',
    placeholderColor: Color(0xFF7A6652),
  ),
  CategoryItem(
    label: 'SPRING\nOUTFITS',
    imagePath: 'assets/Spring.jpg',
    placeholderColor: Color(0xFF4A7C7E),
  ),
  CategoryItem(
    label: 'PRE-FALL\nOUTFITS',
    imagePath: 'assets/Prefall.jpg',
    placeholderColor: Color(0xFF3D3D3D),
  ),
];

const int _kInfiniteBase = 999999;
const int _kInitialPage = _kInfiniteBase ~/ 2;

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 0.74,
    initialPage: _kInitialPage,
  );

  double _currentPage = _kInitialPage.toDouble();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final double page = _pageController.page ?? _kInitialPage.toDouble();
    setState(() {
      _currentPage = page;
      _currentIndex = page.round() % categories.length;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false, // Membiarkan bottom nav menempel ke ujung layar bawah
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 5),
            _buildTitle(),
            const SizedBox(height: 15),
            _buildCarousel(),
            const Spacer(),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _menuLine(width: 24),
                const SizedBox(height: 6),
                _menuLine(width: 24),
                const SizedBox(height: 6),
                _menuLine(width: 14),
              ],
            ),
          ),
          const Text(
            'HYPEN.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: primaryBrown,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.black,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuLine({required double width}) {
    return Container(width: width, height: 2, color: Colors.black);
  }

  Widget _buildTitle() {
    return const Center(
      child: Text(
        'Categories',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.black,
          letterSpacing: -1.0, // Dibuat rapat sesuai desain
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 520, // Ketinggian ditambah agar tombol panah tidak terpotong (clipped)
      child: PageView.builder(
        controller: _pageController,
        itemCount: _kInfiniteBase,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final int realIndex = index % categories.length;

          final double distance = (_currentPage - index).abs();
          final double scale = lerpDouble(1.0, 0.90, distance.clamp(0, 1))!;
          final double opacity = lerpDouble(1.0, 0.60, distance.clamp(0, 1))!;

          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: _CategoryCard(
                item: categories[realIndex],
                isActive: realIndex == _currentIndex &&
                    (index - _currentPage).abs() < 0.5,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Teks WOMEN & MEN
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(label: 'WOMEN', isActive: false),
                  _navItem(label: 'MEN', isActive: false),
                ],
              ),
            ),
          ),
          // Shape Lengkungan Custom (Hump)
          Positioned(
            bottom: 0,
            child: SizedBox(
              width: 140, // Lebar area gambar custom shape
              height: 80,
              child: CustomPaint(
                painter: _BottomTabPainter(color: primaryBrown),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 18), // Posisi icon home
                    child: Icon(
                      Icons.home_outlined, // Placeholder house outline
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({required String label, required bool isActive}) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.black : Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem item;
  final bool isActive;

  const _CategoryCard({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Margin bottom memberikan ruang agar tombol panah yang tumpah (overflow) tidak terpotong PageView
      margin: const EdgeInsets.only(bottom: 50, top: 10, left: 10, right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Background Card ──────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8), // Sudut lebih tajam sesuai desain
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: item.placeholderColor),
                  Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),

                  // Gradient Hitam Lembut
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Icon Heart
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {},
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),

                  // Text Category Label
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 45,
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        height: 1.05, // Jarak antar baris dipersempit
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Arrow Button ──────────────────────────────
          Positioned(
            bottom: -35,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 78 : 64,
                  height: isActive ? 78 : 64,
                  decoration: BoxDecoration(
                    color: primaryBrown,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6), // Border putih tebal
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM PAINTER UNTUK BOTTOM NAVIGATION (HUMP) ──
class _BottomTabPainter extends CustomPainter {
  final Color color;

  _BottomTabPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();

    final w = size.width;
    final h = size.height;

    // Pengaturan dimensi lengkungan
    final humpWidth = 80.0;
    final startX = (w - humpWidth) / 2;
    final endX = startX + humpWidth;
    final bottomRadius = 26.0;
    final topRadius = 20.0;

    path.moveTo(0, h);
    path.lineTo(startX - bottomRadius, h);
    // Lengkungan cekung kiri (pertemuan dengan bar bawah)
    path.quadraticBezierTo(startX, h, startX, h - bottomRadius);
    // Garis lurus ke atas
    path.lineTo(startX, topRadius);
    // Lengkungan cembung atas kiri
    path.quadraticBezierTo(startX, 0, startX + topRadius, 0);
    // Garis lurus atap
    path.lineTo(endX - topRadius, 0);
    // Lengkungan cembung atas kanan
    path.quadraticBezierTo(endX, 0, endX, topRadius);
    // Garis lurus ke bawah
    path.lineTo(endX, h - bottomRadius);
    // Lengkungan cekung kanan
    path.quadraticBezierTo(endX, h, endX + bottomRadius, h);
    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}