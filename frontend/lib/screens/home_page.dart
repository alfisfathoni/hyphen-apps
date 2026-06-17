import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyphen/screens/user_profile.dart';
import 'package:hyphen/screens/search_page.dart';
import 'package:hyphen/screens/cart_page.dart';
import 'package:hyphen/managers/cart_manager.dart';
import 'package:hyphen/helpers/cart_helper.dart';
import 'package:hyphen/data/mock_products.dart';
import 'package:hyphen/screens/sell_page.dart';
import 'package:hyphen/managers/product_manager.dart';
import 'package:hyphen/screens/admin_page.dart';
import 'package:hyphen/widgets/user_drawer.dart';
import 'package:hyphen/screens/inbox_page.dart';
import 'package:hyphen/managers/auth_manager.dart';
import 'package:hyphen/screens/hot_items_page.dart';
import 'package:hyphen/screens/search_results_page.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  int _devTapCount = 0;
  DateTime? _lastDevTapTime;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Fetch real products and check login status when Home Page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ProductManager().fetchProducts();
      final isLoggedIn = await AuthManager().checkAuthStatus();
      if (isLoggedIn && AuthManager().role == 'admin') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPage()),
          );
        }
      }
    });
  }

  void _onDeveloperTap() {
    final now = DateTime.now();
    if (_lastDevTapTime == null || now.difference(_lastDevTapTime!) > const Duration(seconds: 2)) {
      _devTapCount = 1;
    } else {
      _devTapCount++;
    }
    _lastDevTapTime = now;

    if (_devTapCount >= 3) {
      _devTapCount = 0; // Reset counter
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome Admin! Entering Admin Portal...'),
          duration: Duration(milliseconds: 800),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminPage()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: UserDrawer(
        currentTab: _selectedIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: GestureDetector(
          onTap: _onDeveloperTap,
          behavior: HitTestBehavior.opaque,
          child: Text(
            'HYPEN.',
            style: GoogleFonts.plusJakartaSans(
              color: brandBrown,
              fontWeight: FontWeight.w700,
              fontSize: 20, 
              letterSpacing: 1.0,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: CartManager(),
            builder: (context, child) {
              final count = CartManager().totalQuantity;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                    onPressed: () {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartPage(),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _buildBody(brandBrown),
      
      // Custom Bottom Navigation Bar
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: ListenableBuilder(
          listenable: AuthManager(),
          builder: (context, child) {
            final auth = AuthManager();
            final Widget profileIcon;
            final Widget activeProfileIcon;

            if (auth.isLoggedIn) {
              final ImageProvider imgProvider = auth.photoUrl.isNotEmpty
                  ? NetworkImage(auth.photoUrl)
                  : const AssetImage('assets/images/user_avatar.png') as ImageProvider;

              profileIcon = Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black38, width: 1),
                  image: DecorationImage(
                    image: imgProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
              activeProfileIcon = Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  image: DecorationImage(
                    image: imgProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            } else {
              profileIcon = const Icon(Icons.person_outline);
              activeProfileIcon = const Icon(Icons.person);
            }

            return BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black54,
              selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500),
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Jual'),
                const BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Inbox'),
                BottomNavigationBarItem(icon: profileIcon, activeIcon: activeProfileIcon, label: 'Profil'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(Color brandBrown) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeFeed(brandBrown);
      case 1:
        return const SearchPage();
      case 2:
        return SellPage(
          showAppBar: false,
          onUploadSuccess: () {
            setState(() {
              _selectedIndex = 0; // Return to home on successful upload
            });
          },
        );
      case 3:
        return const InboxPage();
      case 4:
        return UserProfile(
          onJualPressed: () => setState(() => _selectedIndex = 2),
        );
      default:
        return Center(
          child: Text(
            'Tab ${_selectedIndex + 1} Placeholder',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  Widget _buildHomeFeed(Color brandBrown) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // For You Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'For You',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchResultsPage(),
                      ),
                    );
                  },
                  child: Text(
                    'See all',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // For You Carousel (Dynamic using ProductManager)
          ListenableBuilder(
            listenable: ProductManager(),
            builder: (context, child) {
              final manager = ProductManager();
              if (manager.isLoading) {
                return const SizedBox(
                  height: 520,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF8C7355)),
                  ),
                );
              }
              final products = manager.products.where((p) => p.isVerified).toList();
              if (products.isEmpty) {
                return const SizedBox(
                  height: 520,
                  child: Center(
                    child: Text('Belum ada produk', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return SizedBox(
                height: 520,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 0.0, bottom: 0.0),
                  itemCount: products.length > 5 ? 5 : products.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: _buildProductCard(products[index]),
                    );
                  },
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Hot Items Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: brandBrown,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hot Items',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HotItemsPage(),
                            ),
                          );
                        },
                        child: Text(
                          'See all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Hot Items Carousel (Dynamic using ProductManager)
                ListenableBuilder(
                  listenable: ProductManager(),
                  builder: (context, child) {
                    final manager = ProductManager();
                    if (manager.isLoading) {
                      return const SizedBox(
                        height: 520,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    final products = manager.products.where((p) => p.isVerified).toList();
                    // Sort by views count descending
                    products.sort((a, b) => b.views.compareTo(a.views));
                    final displayProducts = products;
                    if (displayProducts.isEmpty) {
                      return const SizedBox(
                        height: 520,
                        child: Center(
                          child: Text('Belum ada produk', style: TextStyle(color: Colors.white70)),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 520,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 0.0, bottom: 0.0),
                        itemCount: displayProducts.length > 5 ? 5 : displayProducts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: _buildProductCard(displayProducts[index], onDark: true),
                          );
                        },
                      ),
                    );
                  },
                ),
                // Space to avoid BottomNavigationBar overlapping content
                const SizedBox(height: 100), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, {bool onDark = false}) {
    final Color titleColor = onDark ? Colors.white : Colors.black;
    final Color subtitleColor = onDark ? Colors.white70 : Colors.black54;
    final Color priceColor = onDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () {
        ProductManager().fetchProductDetail(product.id);
        CartHelper.showSizeSelector(context, product);
      },
      child: SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: product.imageUrl.startsWith('http')
                  ? Image.network(
                      product.imageUrl,
                      height: 360,
                      width: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 360,
                        width: 280,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    )
                  : Image.asset(
                      product.imageUrl.isNotEmpty ? product.imageUrl : 'assets/images/placeholder.png',
                      height: 360,
                      width: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 360,
                        width: 280,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              product.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${product.size} · ${product.condition}${onDark ? ' · ${product.views} views' : ''}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.formattedPrice,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: priceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
