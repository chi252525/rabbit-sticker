import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as handler;

enum PermissionType {
  camera,
  bluetooth,
  location,
  storage,
}

class PermissionStatus {
  final PermissionType type;
  final bool isGranted;
  final bool isPermanentlyDenied;
  final String name;

  PermissionStatus({
    required this.type,
    required this.isGranted,
    required this.isPermanentlyDenied,
    required this.name,
  });
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// 檢查單個權限狀態
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    handler.Permission permission = _getPermission(type);
    final status = await permission.status;
    
    return PermissionStatus(
      type: type,
      isGranted: status.isGranted,
      isPermanentlyDenied: status.isPermanentlyDenied,
      name: _getPermissionName(type),
    );
  }

  /// 檢查所有必要權限
  Future<Map<PermissionType, PermissionStatus>> checkAllPermissions() async {
    final Map<PermissionType, PermissionStatus> results = {};

    // 檢查相機權限
    results[PermissionType.camera] = await checkPermission(PermissionType.camera);

    // 檢查藍牙權限
    if (Platform.isAndroid) {
      results[PermissionType.bluetooth] = await checkPermission(PermissionType.bluetooth);
    }

    // 檢查位置權限（某些 Android 版本需要位置權限才能掃描藍牙）
    if (Platform.isAndroid) {
      results[PermissionType.location] = await checkPermission(PermissionType.location);
    }

    // 檢查存儲權限（用於保存照片）
    if (Platform.isAndroid) {
      results[PermissionType.storage] = await checkPermission(PermissionType.storage);
    }

    return results;
  }

  /// 請求單個權限
  Future<bool> requestPermission(PermissionType type) async {
    handler.Permission permission = _getPermission(type);
    final status = await permission.request();
    
    return status.isGranted;
  }

  /// 請求所有必要權限
  Future<Map<PermissionType, bool>> requestAllPermissions() async {
    final Map<PermissionType, bool> results = {};

    // 請求相機權限
    results[PermissionType.camera] = await requestPermission(PermissionType.camera);

    // 請求藍牙權限
    if (Platform.isAndroid) {
      results[PermissionType.bluetooth] = await requestPermission(PermissionType.bluetooth);
    }

    // 請求位置權限
    if (Platform.isAndroid) {
      results[PermissionType.location] = await requestPermission(PermissionType.location);
    }

    // 請求存儲權限
    if (Platform.isAndroid) {
      results[PermissionType.storage] = await requestPermission(PermissionType.storage);
    }

    return results;
  }

  /// 打開應用設置頁面（當權限被永久拒絕時）
  Future<bool> openAppSettings() async {
    return await handler.openAppSettings();
  }

  /// 獲取權限對象
  handler.Permission _getPermission(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return handler.Permission.camera;
      case PermissionType.bluetooth:
        if (Platform.isAndroid) {
          return handler.Permission.bluetoothScan;
        }
        return handler.Permission.bluetooth;
      case PermissionType.location:
        return handler.Permission.location;
      case PermissionType.storage:
        if (Platform.isAndroid) {
          // Android 13+ 使用新的權限
          return handler.Permission.photos;
        }
        return handler.Permission.storage;
    }
  }

  /// 獲取權限名稱
  String _getPermissionName(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return '相機';
      case PermissionType.bluetooth:
        return '藍牙';
      case PermissionType.location:
        return '位置';
      case PermissionType.storage:
        return '存儲';
    }
  }

  /// 檢查是否有未授予的權限
  Future<List<PermissionStatus>> getDeniedPermissions() async {
    final allPermissions = await checkAllPermissions();
    return allPermissions.values
        .where((status) => !status.isGranted)
        .toList();
  }

  /// 檢查是否有被永久拒絕的權限
  Future<List<PermissionStatus>> getPermanentlyDeniedPermissions() async {
    final allPermissions = await checkAllPermissions();
    return allPermissions.values
        .where((status) => status.isPermanentlyDenied)
        .toList();
  }
}

