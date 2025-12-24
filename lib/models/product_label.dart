class ProductLabel {
  final String? productName;
  final String? barcode;
  final String? price;
  final double? confidence;

  ProductLabel({
    this.productName,
    this.barcode,
    this.price,
    this.confidence,
  });

  factory ProductLabel.fromJson(Map<String, dynamic> json) {
    return ProductLabel(
      productName: json['productName'] as String?,
      barcode: json['barcode'] as String?,
      price: json['price'] as String?,
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'barcode': barcode,
      'price': price,
      'confidence': confidence,
    };
  }

  bool get isEmpty {
    return productName == null &&
        barcode == null &&
        price == null;
  }

  @override
  String toString() {
    return 'ProductLabel(productName: $productName, barcode: $barcode, price: $price)';
  }
}

