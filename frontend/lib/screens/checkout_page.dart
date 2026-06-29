import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyphen/managers/cart_manager.dart';
import 'package:hyphen/managers/checkout_manager.dart';
import 'package:hyphen/models/city.dart';
import 'package:hyphen/widgets/city_autocomplete_field.dart';
import 'package:hyphen/screens/payment_page.dart';
import 'package:hyphen/managers/address_manager.dart';
import 'package:hyphen/helpers/notification_helper.dart';
import 'package:hyphen/services/api_client.dart';
import 'package:hyphen/managers/product_manager.dart';

// Address model
class AddressInfo {
  final String? id;
  final String name;
  final String phone;
  final String fullAddress;
  final String? cityId;
  final String? cityLabel;

  AddressInfo({
    this.id,
    required this.name,
    required this.phone,
    required this.fullAddress,
    this.cityId,
    this.cityLabel,
  });
}

// Courier option model representing RajaOngkir outputs
class CourierOption {
  final String serviceName; // JTR, REG, OKE, YES
  final String courierName; // JNE Express
  final double price;
  final String etd; // Estimated Time of Delivery

  CourierOption({
    required this.serviceName,
    required this.courierName,
    required this.price,
    required this.etd,
  });
}

// Payment Option model
class PaymentOption {
  final String name;
  final String type; // QRIS, BCA, STRIPE

  PaymentOption({
    required this.name,
    required this.type,
  });
}

class CheckoutPage extends StatefulWidget {
  final CartItem checkoutItem;

  const CheckoutPage({super.key, required this.checkoutItem});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  AddressInfo? _address;
  CourierOption? _selectedCourier;
  PaymentOption? _selectedPayment;

  // Mock list of courier options (RajaOngkir preparation)
  final List<CourierOption> _courierOptions = [
    CourierOption(courierName: 'JNE', serviceName: 'OKE', price: 12000.0, etd: '3-4'),
    CourierOption(courierName: 'JNE', serviceName: 'REG', price: 18000.0, etd: '2-3'),
    CourierOption(courierName: 'JNE', serviceName: 'YES', price: 28000.0, etd: '1'),
  ];

  // Calculate pricing summary
  double get _subtotal {
    return widget.checkoutItem.product.price * widget.checkoutItem.quantity;
  }

  double get _shippingFee {
    return _selectedCourier?.price ?? 0.0;
  }

  double get _serviceFee => _address != null ? 2000.0 : 0.0;
  double get _total => _subtotal + _shippingFee + _serviceFee;

  // Helper string formatter
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

  @override
  void initState() {
    super.initState();
    // Default JNE Reguler
    _selectedCourier = _courierOptions[1]; // JNE Reguler

    // Default payment method is QRIS
    _selectedPayment = PaymentOption(name: 'QRIS', type: 'QRIS');

    // Clear SnackBar & auto-load default address
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ScaffoldMessenger.of(context).clearSnackBars();
      
      try {
        await AddressManager().fetchAddresses();
        final defAddress = AddressManager().defaultAddress;
        if (defAddress != null && mounted) {
          setState(() {
            _address = AddressInfo(
              id: defAddress.id,
              name: defAddress.recipientName,
              phone: defAddress.phone,
              fullAddress: defAddress.fullAddress,
              cityId: defAddress.destinationCityId,
              cityLabel: defAddress.destinationCityLabel,
            );
          });
        }
      } catch (e) {
        debugPrint('Error loading default address: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    final hasAddress = _address != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Section (Alamat) - Rendered at top
                    _buildAddressSection(brandBrown),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                    // Item and Shipping Selection
                    _buildItemAndShipping(brandBrown),

                    // Payment Method Section (Pembayaran)
                    _buildPaymentMethodSection(brandBrown),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                    // Price Section (Harga)
                    _buildPriceSection(hasAddress),
                  ],
                ),
              ),
            ),

            // Checkout / Payment action panel at the bottom
            _buildBottomPanel(brandBrown),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(Color brandBrown) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alamat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          if (_address == null)
            InkWell(
              onTap: _openPengisianForm,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.black87, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Tambah alamat',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Untuk opsi & biaya pengiriman',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _address!.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _address!.phone,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _address!.fullAddress,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.black87, size: 20),
                    onPressed: _openPengisianForm,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemAndShipping(Color brandBrown) {
    final hasAddress = _address != null;
    final item = widget.checkoutItem;
    final brand = item.product.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Header
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 8.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  brand.substring(0, brand.length > 2 ? 2 : brand.length).toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: brandBrown,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                brand.toLowerCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // Item
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  item.product.imageUrl,
                  height: 70,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.size} · ${item.product.condition}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatVal(item.product.price)}  x ${item.quantity}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatVal(item.product.price * item.quantity),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // Courier Selection
        if (hasAddress)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: InkWell(
              onTap: () => _openCourierSelector(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    _buildJneLogo(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCourier != null
                                ? '${_selectedCourier!.courierName} (${_selectedCourier!.serviceName})'
                                : 'Pilih Pengiriman',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedCourier != null
                                ? 'Estimasi tiba ${_selectedCourier!.etd} hari · ${_formatVal(_selectedCourier!.price)}'
                                : 'Tekan untuk memilih kurir',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_right, color: Colors.black54, size: 20),
                  ],
                ),
              ),
            ),
          ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Divider(height: 16, thickness: 1, color: Color(0xFFEEEEEE)),
        ),
      ],
    );
  }

  void _openCourierSelector() {
    ScaffoldMessenger.of(context).clearSnackBars();
    const Color brandBrown = Color(0xFF8C7355);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Pengiriman',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _courierOptions.length,
                  itemBuilder: (context, index) {
                    final courier = _courierOptions[index];
                    final isSelected = _selectedCourier?.serviceName == courier.serviceName;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCourier = courier;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? brandBrown : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildJneLogo(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${courier.courierName} (${courier.serviceName})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Estimasi tiba ${courier.etd} hari · ${_formatVal(courier.price)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: brandBrown, size: 20)
                            else
                              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodSection(Color brandBrown) {
    final isSelected = _selectedPayment != null;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metode Pembayaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _openPaymentSelector,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isSelected
                  ? Row(
                      children: [
                        _buildPaymentLogo(_selectedPayment!.type),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _selectedPayment!.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_right, color: Colors.black54, size: 20),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.black87, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Pilih Metode Pembayaran',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPaymentSelector() {
    ScaffoldMessenger.of(context).clearSnackBars();
    const Color brandBrown = Color(0xFF8C7355);
    final List<PaymentOption> paymentOptions = [
      PaymentOption(name: 'QRIS', type: 'QRIS'),
      PaymentOption(name: 'BCA Virtual Account', type: 'BCA'),
      PaymentOption(name: 'Credit Card / Stripe', type: 'STRIPE'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Metode Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paymentOptions.length,
                  itemBuilder: (context, index) {
                    final payment = paymentOptions[index];
                    final isSelected = _selectedPayment?.type == payment.type;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPayment = payment;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? brandBrown : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildPaymentLogo(payment.type),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                payment.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: brandBrown, size: 20)
                            else
                              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceSection(bool hasAddress) {
    final int totalItems = widget.checkoutItem.quantity;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Harga',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('$totalItems Item', _formatVal(_subtotal)),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Pengiriman',
            _selectedCourier != null ? _formatVal(_shippingFee) : '-',
            valueColor: _selectedCourier != null ? Colors.black : Colors.grey,
          ),
          if (hasAddress) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Biaya Layanan', _formatVal(_serviceFee)),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color valueColor = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(Color brandBrown) {
    final readyToPay = _address != null && _selectedCourier != null && _selectedPayment != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          // Total price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatVal(_total),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Pay Button
          Expanded(
            child: ElevatedButton(
              onPressed: readyToPay ? _navigateToPayment : _openPengisianForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: readyToPay ? brandBrown : Colors.grey.shade300,
                foregroundColor: readyToPay ? Colors.white : Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: readyToPay ? 4 : 0,
              ),
              child: Text(
                readyToPay ? 'Bayar sekarang' : 'Pilih Alamat',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment() async {
    if (_address == null || _selectedCourier == null || _selectedPayment == null) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8C7355)),
      ),
    );

    final result = await CheckoutManager().processSingleItemCheckout(
      productId: widget.checkoutItem.product.id,
      addressId: _address!.id ?? '', // We assume address has an ID from backend now
      courierCode: _selectedCourier!.courierName.toLowerCase().split(' ')[0], // Simplistic mapping for now
      service: _selectedCourier!.serviceName,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (!result.success) {
      SnackBarHelper.show(
        context,
        result.message ?? 'Checkout gagal',
        title: 'Checkout Gagal',
        isError: true,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          checkoutItem: widget.checkoutItem,
          totalPrice: _total,
          selectedPayment: _selectedPayment!,
          snapUrl: result.snapUrl,
          snapToken: result.snapToken,
        ),
      ),
    );

    if (mounted) {
      // If CheckoutPage is still mounted, it means the user manually closed / backed out of the payment flow.
      // We should cancel the order to release the locked product stock so they (or others) can buy it again.
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8C7355)),
        ),
      );

      bool cancelSuccess = false;
      try {
        if (result.orderId != null) {
          final cancelResponse = await ApiClient().dio.post('/order/cancel/${result.orderId}');
          if (cancelResponse.statusCode == 200) {
            cancelSuccess = true;
          }
        }
      } catch (e) {
        debugPrint('Error cancelling order: $e');
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (cancelSuccess) {
          // If cancellation was successful, it means the order was indeed pending/waiting and is now cancelled.
          // Refresh the product list so the item is shown as available again (stock = 1)
          ProductManager().fetchProducts(force: true);

          // Show a cancellation snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran dibatalkan. Pesanan dibatalkan dan stok produk telah dikembalikan.'),
              duration: Duration(seconds: 4),
            ),
          );

          // Return back to the Cart Page / previous page
          Navigator.pop(context);
        } else {
          // If cancellation failed, it is highly likely that the order status is already 'paid'
          // (because the payment succeeded and the webhook updated the database).
          // We treat this as a successful purchase!
          
          // 1. Clear purchased item from Cart
          final cartManager = CartManager();
          cartManager.removeItem(widget.checkoutItem.product.id, widget.checkoutItem.size);

          // 2. Refresh products list
          ProductManager().fetchProducts(force: true);

          // 3. Return to Home Page
          Navigator.popUntil(context, (route) => route.isFirst);

          // 4. Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan berhasil diproses! Silakan cek menu Profil -> Order History untuk status pembayaran.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _openPengisianForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPengisianPage(
          initialAddress: _address,
        ),
      ),
    );

    if (result != null && result is AddressInfo) {
      setState(() {
        _address = result;
      });
    }
  }

  Widget _buildJneLogo() {
    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'JNE',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            height: 3,
            width: 32,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLogo(String type) {
    Color bgColor = Colors.black;
    String label = '';
    switch (type) {
      case 'QRIS':
        bgColor = Colors.blue.shade800;
        label = 'QRIS';
        break;
      case 'BCA':
        bgColor = Colors.blue.shade600;
        label = 'BCA';
        break;
      case 'STRIPE':
        bgColor = const Color(0xFF635BFF);
        label = 'stripe';
        break;
    }

    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkout Page - Pengisian (Address Form Screen Only)
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutPengisianPage extends StatefulWidget {
  final AddressInfo? initialAddress;

  const CheckoutPengisianPage({
    super.key,
    this.initialAddress,
  });

  @override
  State<CheckoutPengisianPage> createState() => _CheckoutPengisianPageState();
}

class _CheckoutPengisianPageState extends State<CheckoutPengisianPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  City? _selectedCity;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _nameController.text = widget.initialAddress!.name;
      _phoneController.text = widget.initialAddress!.phone;
      _addressController.text = widget.initialAddress!.fullAddress;
    } else {
      // Keep controllers empty initially so examples act as hints/placeholders
      _nameController.text = '';
      _phoneController.text = '';
      _addressController.text = '';
    }

    // Clear SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Section
                    Text(
                      'Alamat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Nama Penerima',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
                              hintText: 'Contoh: Joel Abner',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black26),
                              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Nomor Telepon',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
                              hintText: 'Contoh: 089507274535',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black26),
                              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CityAutocompleteField(
                            labelText: 'Kota Tujuan',
                            hintText: 'Ketik nama kota, misal: Jakarta Selatan',
                            initialValue: _selectedCity?.label,
                            onSelected: (City city) {
                              setState(() {
                                _selectedCity = city;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressController,
                            maxLines: 3,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, 
                              height: 1.4,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Alamat Lengkap',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
                              hintText: 'Contoh: Jalan Sandang No D5B, RT 1/RW 11, Palmerah, Kota Jakarta Barat, DKI Jakarta, ID 11480',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black26),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Save details button at the bottom
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              child: ElevatedButton(
                onPressed: _saveAndReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBrown,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Simpan Alamat',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAndReturn() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      SnackBarHelper.show(
        context,
        'Harap lengkapi semua input data pengisian.',
        title: 'Formulir Belum Lengkap',
        isError: true,
      );
      return;
    }

    const Color brandBrown = Color(0xFF8C7355);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: brandBrown),
      ),
    );

    final error = await AddressManager().addAddress(
      label: 'Utama',
      recipientName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      postalCode: '11480',
      destinationCityId: _selectedCity?.id.toString() ?? '1',
      destinationCityLabel: _selectedCity?.label ?? 'Jakarta',
      isDefault: true,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (error != null) {
      SnackBarHelper.show(
        context,
        'Gagal menyimpan alamat: $error',
        title: 'Penyimpanan Gagal',
        isError: true,
      );
      return;
    }

    // Find the newly added address in the list
    final newAddress = AddressManager().addresses.firstWhere(
      (a) => a.recipientName == _nameController.text.trim() && a.fullAddress == _addressController.text.trim(),
      orElse: () => AddressManager().addresses.first,
    );

    final address = AddressInfo(
      id: newAddress.id,
      name: newAddress.recipientName,
      phone: newAddress.phone,
      fullAddress: newAddress.fullAddress,
      cityId: newAddress.destinationCityId,
      cityLabel: newAddress.destinationCityLabel,
    );

    Navigator.pop(context, address);
  }
}
