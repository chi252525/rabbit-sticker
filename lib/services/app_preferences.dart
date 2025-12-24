import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyPermissionsRequested = 'permissions_requested';

  /// 檢查是否是首次啟動
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// 設置已啟動標記
  static Future<void> setLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  /// 檢查是否已請求過權限
  static Future<bool> hasRequestedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPermissionsRequested) ?? false;
  }

  /// 設置已請求權限標記
  static Future<void> setPermissionsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionsRequested, true);
  }

  /// 重置所有設置（用於測試）
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstLaunch);
    await prefs.remove(_keyPermissionsRequested);
  }
}

