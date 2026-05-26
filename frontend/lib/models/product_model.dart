class Product {
  final String id;
  final String sellerId;
  final String title;
  final String brand; // Backend doesn't explicitly store brand, mapping to category or default
  final double price; 
  final String imageUrl;
  final String size;
  final String condition;
  final String category; 
  final bool isVerified;
  final int views;

  const Product({
    required this.id,
    required this.title,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.size,
    required this.condition,
    required this.category,
    this.isVerified = true,
    this.sellerId = '',
    this.views = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Determine size from sizes array if it exists
    String sizeStr = 'M';
    if (json['sizes'] != null && (json['sizes'] as List).isNotEmpty) {
      sizeStr = json['sizes'][0]['size']?.toString() ?? 'M';
    }

    // Try parsing as numeric string or double/int
    double parsedPrice = 0.0;
    if (json['productPrice'] != null) {
      if (json['productPrice'] is String) {
        parsedPrice = double.tryParse(json['productPrice']) ?? 0.0;
      } else {
        parsedPrice = (json['productPrice'] as num).toDouble();
      }
    }

    return Product(
      id: json['productId']?.toString() ?? '',
      sellerId: json['sellerID']?.toString() ?? '',
      title: json['productName'] ?? 'Unknown Product',
      brand: 'Hyphen', // Fallback brand
      price: parsedPrice,
      imageUrl: json['productImage'] ?? '',
      size: sizeStr,
      condition: _mapCondition(json['item_condition']),
      category: json['productCategory'] ?? 'Daily',
      isVerified: json['status'] == 'approved',
      views: json['views'] is int ? json['views'] : (int.tryParse(json['views']?.toString() ?? '') ?? 0),
    );
  }

  static String _mapCondition(String? backendCondition) {
    switch (backendCondition) {
      case 'like_new':
        return 'Sangat Baik';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Cukup Baik';
      default:
        return 'Baik';
    }
  }

  Product copyWith({
    String? id,
    String? title,
    String? brand,
    double? price,
    String? imageUrl,
    String? size,
    String? condition,
    String? category,
    bool? isVerified,
    String? sellerId,
    int? views,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      isVerified: isVerified ?? this.isVerified,
      sellerId: sellerId ?? this.sellerId,
      views: views ?? this.views,
    );
  }

  String get formattedPrice {
    // Basic Indonesian Rupiah formatting: Rp 250.000
    final buffer = StringBuffer('Rp ');
    final priceStr = price.toInt().toString();
    final len = priceStr.length;
    for (int i = 0; i < len; i++) {
      buffer.write(priceStr[i]);
      if ((len - i - 1) % 3 == 0 && i != len - 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}
