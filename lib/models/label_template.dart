enum LabelSize {
  small,
  medium,
  large,
}

enum LabelStyle {
  textOnly,
  textWithBarcode,
  barcodeOnly,
}

class LabelTemplate {
  final String id;
  final String name;
  final LabelSize size;
  final LabelStyle style;
  final Map<String, dynamic> config;

  LabelTemplate({
    required this.id,
    required this.name,
    required this.size,
    required this.style,
    this.config = const {},
  });

  // 获取尺寸对应的数值
  double get width {
    switch (size) {
      case LabelSize.small:
        return 200;
      case LabelSize.medium:
        return 300;
      case LabelSize.large:
        return 400;
    }
  }

  double get height {
    switch (size) {
      case LabelSize.small:
        return 100;
      case LabelSize.medium:
        return 150;
      case LabelSize.large:
        return 200;
    }
  }

  // 预设模板
  static List<LabelTemplate> getPresetTemplates() {
    return [
      LabelTemplate(
        id: 'small_text_barcode',
        name: '小尺寸 - 文字+條碼',
        size: LabelSize.small,
        style: LabelStyle.textWithBarcode,
      ),
      LabelTemplate(
        id: 'medium_text_barcode',
        name: '中尺寸 - 文字+條碼',
        size: LabelSize.medium,
        style: LabelStyle.textWithBarcode,
      ),
      LabelTemplate(
        id: 'large_text_barcode',
        name: '大尺寸 - 文字+條碼',
        size: LabelSize.large,
        style: LabelStyle.textWithBarcode,
      ),
      LabelTemplate(
        id: 'small_text_only',
        name: '小尺寸 - 僅文字',
        size: LabelSize.small,
        style: LabelStyle.textOnly,
      ),
      LabelTemplate(
        id: 'medium_text_only',
        name: '中尺寸 - 僅文字',
        size: LabelSize.medium,
        style: LabelStyle.textOnly,
      ),
      LabelTemplate(
        id: 'large_text_only',
        name: '大尺寸 - 僅文字',
        size: LabelSize.large,
        style: LabelStyle.textOnly,
      ),
      LabelTemplate(
        id: 'small_barcode_only',
        name: '小尺寸 - 僅條碼',
        size: LabelSize.small,
        style: LabelStyle.barcodeOnly,
      ),
      LabelTemplate(
        id: 'medium_barcode_only',
        name: '中尺寸 - 僅條碼',
        size: LabelSize.medium,
        style: LabelStyle.barcodeOnly,
      ),
      LabelTemplate(
        id: 'large_barcode_only',
        name: '大尺寸 - 僅條碼',
        size: LabelSize.large,
        style: LabelStyle.barcodeOnly,
      ),
    ];
  }
}

