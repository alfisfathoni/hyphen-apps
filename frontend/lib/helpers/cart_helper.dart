import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyphen/managers/cart_manager.dart';
import 'package:hyphen/data/mock_products.dart';
import 'package:hyphen/screens/cart_page.dart';
import 'package:hyphen/managers/chat_manager.dart';
import 'package:hyphen/managers/auth_manager.dart';
import 'package:hyphen/screens/inbox_page.dart';

class CartHelper {
  static void showSizeSelector(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SizeSelectorSheet(product: product),
    );
  }
}

class _SizeSelectorSheet extends StatefulWidget {
  final Product product;

  const _SizeSelectorSheet({required this.product});

  @override
  State<_SizeSelectorSheet> createState() => _SizeSelectorSheetState();
}

class _SizeSelectorSheetState extends State<_SizeSelectorSheet> {
  final List<String> _sizes = ['S', 'M', 'L', 'XL'];
  late String _selectedSize;
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isStartingChat = false;

  @override
  void initState() {
    super.initState();
    // Default size is L or first size if the product size is custom (like shoes '42'), otherwise 'M'
    _selectedSize = _sizes.contains(widget.product.size) ? widget.product.size : 'M';
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Product Details Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.product.imageUrl.startsWith('http')
                  ? Image.network(
                      widget.product.imageUrl,
                      height: 100,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        width: 80,
                        color: const Color(0xFFF3F3F3),
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Image.asset(
                      widget.product.imageUrl,
                      height: 100,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        width: 80,
                        color: const Color(0xFFF3F3F3),
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.brand,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.formattedPrice,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: brandBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32, thickness: 1),

          // Size Selection Section
          Text(
            'Pilih Ukuran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _sizes.map((size) {
              final isSelected = _selectedSize == size;
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ChoiceChip(
                  label: Text(size),
                  selected: isSelected,
                  selectedColor: Colors.black,
                  backgroundColor: const Color(0xFFF3F3F3),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSize = size;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Quantity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16, color: Colors.black87),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() {
                            _quantity--;
                          });
                        }
                      },
                    ),
                    Text(
                      '$_quantity',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16, color: Colors.black87),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Buttons Row: Chat & Add to Cart
          Row(
            children: [
              // Chat Button
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  border: Border.all(color: brandBrown, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isStartingChat
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: brandBrown, strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: brandBrown, size: 22),
                        onPressed: () async {
                          setState(() {
                            _isStartingChat = true;
                          });

                          final auth = AuthManager();
                          if (!auth.isLoggedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Silakan login terlebih dahulu.')),
                            );
                            setState(() {
                              _isStartingChat = false;
                            });
                            return;
                          }

                          if (auth.userId == widget.product.sellerId) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Anda tidak bisa chat dengan diri sendiri.')),
                            );
                            setState(() {
                              _isStartingChat = false;
                            });
                            return;
                          }

                          final room = await ChatManager().createOrGetRoom(
                            widget.product.sellerId,
                            widget.product.id,
                          );

                          if (!mounted) return;
                          setState(() {
                            _isStartingChat = false;
                          });

                          if (room != null) {
                            Navigator.pop(context); // Close bottom sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailPage(
                                  roomId: room['id'],
                                  name: room['otherUsername'] ?? 'Seller',
                                  avatarUrl: room['otherPhotoUrl'],
                                  productName: room['productName'] ?? widget.product.title,
                                  productPrice: room['productPrice'] != null
                                      ? double.tryParse(room['productPrice'].toString())
                                      : widget.product.price,
                                  productImageUrl: room['productImageUrl'] ?? widget.product.imageUrl,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gagal memulai chat.')),
                            );
                          }
                        },
                      ),
              ),
              const SizedBox(width: 12),

              // Add to Cart Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAddingToCart
                      ? null
                      : () async {
                          setState(() {
                            _isAddingToCart = true;
                          });
                          final error = await CartManager().addItem(
                            widget.product,
                            size: _selectedSize,
                            quantity: _quantity,
                          );
                          
                          if (!mounted) return;
                          
                          setState(() {
                            _isAddingToCart = false;
                          });

                          if (error != null) {
                            Navigator.pop(context); // Close bottom sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                            return;
                          }

                          Navigator.pop(context); // Close bottom sheet

                          // Show snackbar confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('${widget.product.title} ($_selectedSize) dimasukkan ke keranjang.'),
                              duration: const Duration(seconds: 3),
                              action: SnackBarAction(
                                label: 'Lihat Keranjang',
                                textColor: Colors.amber.shade400,
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
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isAddingToCart
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Tambah ke Keranjang',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
