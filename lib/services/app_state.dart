import '../models/product_label.dart';

/// App 狀態管理服務
/// 用於存儲和管理標籤數據
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // 存儲所有標籤的列表
  final List<Map<String, dynamic>> _labels = [];

  /// 添加標籤
  void addLabel(String imagePath, ProductLabel label) {
    _labels.add({
      'imagePath': imagePath,
      'label': label,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 獲取所有標籤
  List<Map<String, dynamic>> getAllLabels() {
    return List.unmodifiable(_labels);
  }

  /// 獲取標籤數量
  int get labelCount => _labels.length;

  /// 清除所有標籤
  void clearAllLabels() {
    _labels.clear();
  }

  /// 刪除指定標籤
  void removeLabel(int index) {
    if (index >= 0 && index < _labels.length) {
      _labels.removeAt(index);
    }
  }
}

