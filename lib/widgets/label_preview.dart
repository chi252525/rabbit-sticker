import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../models/product_label.dart';
import '../models/label_template.dart';

class LabelPreview extends StatelessWidget {
  final ProductLabel label;
  final LabelTemplate template;

  const LabelPreview({
    super.key,
    required this.label,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: template.width,
      height: template.height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: _buildLabelContent(),
    );
  }

  Widget _buildLabelContent() {
    switch (template.style) {
      case LabelStyle.textOnly:
        return _buildTextOnly();
      case LabelStyle.textWithBarcode:
        return _buildTextWithBarcode();
      case LabelStyle.barcodeOnly:
        return _buildBarcodeOnly();
    }
  }

  Widget _buildTextOnly() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (label.productName != null)
          _buildProductName(),
        if (label.price != null)
          _buildPrice(),
      ],
    );
  }

  Widget _buildTextWithBarcode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (label.productName != null)
          _buildProductName(),
        if (label.price != null)
          _buildPrice(),
        if (label.barcode != null)
          _buildBarcode(),
      ],
    );
  }

  Widget _buildBarcodeOnly() {
    return Center(
      child: label.barcode != null ? _buildBarcode() : const SizedBox(),
    );
  }

  Widget _buildProductName() {
    double fontSize;
    switch (template.size) {
      case LabelSize.small:
        fontSize = 14;
        break;
      case LabelSize.medium:
        fontSize = 18;
        break;
      case LabelSize.large:
        fontSize = 24;
        break;
    }

    return Text(
      label.productName!,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPrice() {
    double fontSize;
    switch (template.size) {
      case LabelSize.small:
        fontSize = 16;
        break;
      case LabelSize.medium:
        fontSize = 20;
        break;
      case LabelSize.large:
        fontSize = 28;
        break;
    }

    return Text(
      label.price!,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.red[700],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBarcode() {
    if (label.barcode == null || label.barcode!.isEmpty) {
      return const SizedBox();
    }

    double barcodeHeight;
    switch (template.size) {
      case LabelSize.small:
        barcodeHeight = 40;
        break;
      case LabelSize.medium:
        barcodeHeight = 60;
        break;
      case LabelSize.large:
        barcodeHeight = 80;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BarcodeWidget(
          barcode: Barcode.ean13(),
          data: label.barcode!,
          width: template.width - 24,
          height: barcodeHeight,
          drawText: true,
          style: TextStyle(
            fontSize: template.size == LabelSize.small ? 10 : 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.barcode!,
          style: TextStyle(
            fontSize: template.size == LabelSize.small ? 10 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

