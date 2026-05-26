import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyphen/managers/product_manager.dart';
import 'package:hyphen/widgets/photo_uploader_box.dart';
import 'package:hyphen/widgets/selling_tips_box.dart';
import 'package:hyphen/models/city.dart';
import 'package:hyphen/widgets/city_autocomplete_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hyphen/managers/auth_manager.dart';
import 'package:hyphen/screens/login_page.dart';
import 'package:hyphen/helpers/notification_helper.dart';

class SellPage extends StatefulWidget {
  final VoidCallback? onUploadSuccess;
  final bool showAppBar;

  const SellPage({
    super.key,
    this.onUploadSuccess,
    this.showAppBar = true,
  });

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  String? _selectedImagePath;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'Pilih Kategori';
  double? _enteredPrice;
  String _selectedSize = 'M';
  String _selectedCondition = 'Sangat Baik';
  bool _isUploading = false;
  City? _selectedCity;
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _showPhotoPicker() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  void _showCategoryPicker() {
    const Color brandBrown = Color(0xFF8C7355);
    showModalBottomSheet(
      context: context,
      backgroundColor: brandBrown,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final categories = ['Pria', 'Wanita', 'Daily', 'Formal'];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ...categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        cat,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showPriceInputDialog() {
    final controller = TextEditingController(
      text: _enteredPrice != null ? _enteredPrice!.toInt().toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Input Harga (Rp)',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'cth. 250000',
            hintStyle: TextStyle(color: Colors.black38),
            prefixText: 'Rp ',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed != null) {
                setState(() {
                  _enteredPrice = parsed;
                });
              }
              Navigator.pop(context);
            },
            child: Text(
              'Simpan',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showConditionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        final conditions = ['Sangat Baik', 'Baik', 'Cukup Baik'];
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih Kondisi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ...conditions.map((cond) => ListTile(
                    title: Text(
                      cond,
                      style: GoogleFonts.plusJakartaSans(color: Colors.black87),
                    ),
                    trailing: _selectedCondition == cond
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCondition = cond;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showSizePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        final sizes = ['S', 'M', 'L', 'XL'];
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih Ukuran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ...sizes.map((s) => ListTile(
                    title: Text(
                      s,
                      style: GoogleFonts.plusJakartaSans(color: Colors.black87),
                    ),
                    trailing: _selectedSize == s
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSize = s;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadProduct() async {
    if (_selectedImagePath == null) {
      SnackBarHelper.show(
        context,
        'Silakan tambahkan foto baju terlebih dahulu.',
        isError: true,
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      SnackBarHelper.show(
        context,
        'Silakan masukkan nama baju.',
        isError: true,
      );
      return;
    }
    if (_selectedCategory == 'Pilih Kategori') {
      SnackBarHelper.show(
        context,
        'Silakan pilih kategori.',
        isError: true,
      );
      return;
    }
    if (_enteredPrice == null || _enteredPrice! <= 0) {
      SnackBarHelper.show(
        context,
        'Silakan masukkan harga yang valid.',
        isError: true,
      );
      return;
    }
    if (_selectedCity == null) {
      SnackBarHelper.show(
        context,
        'Silakan pilih kota asal pengiriman.',
        isError: true,
      );
      return;
    }
    if (_weightController.text.trim().isEmpty) {
      SnackBarHelper.show(
        context,
        'Silakan masukkan berat barang.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final errorMessage = await ProductManager().uploadProduct(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? 'Baju preloved berkualitas dari Hyphen' : _descController.text.trim(),
      price: _enteredPrice!,
      category: _selectedCategory,
      size: _selectedSize,
      conditionLabel: _selectedCondition,
      imagePath: _selectedImagePath!,
      originCityId: _selectedCity!.id.toString(),
      originCityLabel: _selectedCity!.label,
      weight: _weightController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isUploading = false;
    });

    if (errorMessage == null) {
      SnackBarHelper.show(
        context,
        '"${_nameController.text.trim()}" berhasil diupload!',
        title: 'Upload Berhasil',
      );

      if (widget.onUploadSuccess != null) {
        widget.onUploadSuccess!();
      } else {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } else {
      SnackBarHelper.show(
        context,
        errorMessage,
        title: 'Upload Gagal',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    )
                  : IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () {},
                    ),
              title: Text(
                'HYPEN.',
                style: GoogleFonts.plusJakartaSans(
                  color: brandBrown,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: 1.0,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      body: ListenableBuilder(
        listenable: AuthManager(),
        builder: (context, child) {
          final auth = AuthManager();
          if (!auth.isLoggedIn) {
            return _buildLoggedOutPlaceholder(context, brandBrown);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PhotoUploaderBox(
                  selectedImagePath: _selectedImagePath,
                  onTap: _showPhotoPicker,
                ),
                const SizedBox(height: 24),

                const SellingTipsBox(),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF3F3F3)),
                  ),
                  child: Column(
                    children: [
                      _buildFormTextRow(
                        label: 'Nama baju',
                        hint: 'cth. Black Jeans',
                        controller: _nameController,
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                      _buildFormTextRow(
                        label: 'Description',
                        hint: 'cth. Tidak ada kerusakan/noda, Ukuran M',
                        controller: _descController,
                        maxLines: 3,
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                      _buildFormSelectorRow(
                        label: 'Kategori',
                        value: _selectedCategory,
                        onTap: _showCategoryPicker,
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                      _buildFormSelectorRow(
                        label: 'Ukuran',
                        value: _selectedSize,
                        onTap: _showSizePicker,
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                      _buildFormSelectorRow(
                        label: 'Kondisi',
                        value: _selectedCondition,
                        onTap: _showConditionPicker,
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                      _buildFormSelectorRow(
                        label: 'Harga',
                        value: _enteredPrice != null
                            ? 'Rp ${_enteredPrice!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
                            : 'Pilih Harga',
                        onTap: _showPriceInputDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Info Pengiriman',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                CityAutocompleteField(
                  onSelected: (City city) {
                    setState(() {
                      _selectedCity = city;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Berat Barang (gram)',
                    hintText: 'Contoh: 500 (untuk 500 gram)',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.black38,
                      fontSize: 14,
                    ),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: const Icon(Icons.scale_outlined, color: Colors.black26),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Upload',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoggedOutPlaceholder(BuildContext context, Color brandBrown) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.lock_outline, size: 40, color: brandBrown),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Masuk Akun',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login terlebih dahulu untuk menjual produk Anda di marketplace.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ).then((_) {
                  setState(() {});
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Masuk Sekarang',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTextRow({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.black38,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSelectorRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != 'Pilih Kategori' && value != 'Pilih Harga';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? Colors.black87 : Colors.black38,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
