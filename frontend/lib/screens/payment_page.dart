import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyphen/managers/cart_manager.dart';
import 'package:hyphen/screens/checkout_page.dart'; // import PaymentOption
import 'package:hyphen/managers/order_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hyphen/managers/product_manager.dart';

class PaymentPage extends StatefulWidget {
  final CartItem checkoutItem;
  final double totalPrice;
  final PaymentOption selectedPayment;
  final String? snapUrl;
  final String? snapToken;

  const PaymentPage({
    super.key,
    required this.checkoutItem,
    required this.totalPrice,
    required this.selectedPayment,
    this.snapUrl,
    this.snapToken,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _step = 1; // Step 1: WebView, Step 2: Congratulations
  late final WebViewController _webViewController;
  bool _isLoadingWebView = true;
  late String _orderId;

  @override
  void initState() {
    super.initState();

    // Generate random order ID for UI display
    final random = Random();
    final idNum = random.nextInt(90000) + 10000;
    _orderId = '#BTR-$idNum';

    // Clear SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });

    if (widget.snapUrl != null) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoadingWebView = false;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.contains('midtrans')) {
                return NavigationDecision.navigate;
              }
              // If midtrans redirects somewhere else (e.g. success page), we can intercept it
              if (request.url.contains('example.com') || request.url.contains('success')) {
                _handlePaymentSuccess();
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.snapUrl!));
    }
  }

  void _handlePaymentSuccess() {
    setState(() {
      _step = 2; // Transition to Congratulations
    });

    // We can fetch real orderId from backend or use a mock one for now
    OrderManager().addOrderFromCheckout(_orderId, [widget.checkoutItem]);

    // Clear purchased item from Cart
    final cartManager = CartManager();
    cartManager.removeItem(widget.checkoutItem.product.id, widget.checkoutItem.size);

    // Refresh products list
    ProductManager().fetchProducts(force: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    if (_step == 2) {
      return _buildCongratulationsScreen(brandBrown);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pembayaran',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: widget.snapUrl == null
          ? Center(
              child: Text(
                'Gagal memuat halaman pembayaran',
                style: GoogleFonts.plusJakartaSans(color: Colors.red),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoadingWebView)
                  const Center(
                    child: CircularProgressIndicator(color: brandBrown),
                  ),
              ],
            ),
    );
  }

  // Formatting price string
  String _formatVal(double val) {
    final buffer = StringBuffer('Rp ');
    final priceStr = val.toInt().toString();
    final len = priceStr.length;
    for (int i = 0; i < len; i++) {
      buffer.write(priceStr[i]);
      if ((len - i - 1) % 3 == 0 && i != len - 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  // Payment Page 2: Congratulations Success Landing
  Widget _buildCongratulationsScreen(Color brandBrown) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Clean look, no back button on success
        title: Text(
          'HYPEN.',
          style: GoogleFonts.plusJakartaSans(
            color: brandBrown,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {
              // Pop to HomePage
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Shield Checkmark Logo (Bronze style)
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: brandBrown.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: brandBrown.withValues(alpha: 0.3), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: brandBrown,
                    size: 72,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Congratulations Header
              Text(
                'Congratulations',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: brandBrown,
                ),
              ),
              const SizedBox(height: 12),

              // Order detail
              Text(
                'Thank you for your purchase. Your order ID is $_orderId',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Total Paid
              Text(
                _formatVal(widget.totalPrice),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: brandBrown,
                ),
              ),
              const SizedBox(height: 32),

              // Alert Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: brandBrown.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: brandBrown, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your order has been successfully paid. Please check your order details in the "Orders" menu.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: brandBrown,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Home and Pesanan actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Pop all routes back to home page
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Home',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // In high fidelity ecommerce, show orders. For now, pop back to home page
                        // and show a nice snackbar confirmation
                        Navigator.popUntil(context, (route) => route.isFirst);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Menampilkan detail pesanan untuk order $_orderId'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Pesanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
