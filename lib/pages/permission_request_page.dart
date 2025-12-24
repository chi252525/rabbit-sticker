import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../services/app_preferences.dart';

class PermissionRequestPage extends StatefulWidget {
  final bool isFirstLaunch;

  const PermissionRequestPage({
    super.key,
    this.isFirstLaunch = true,
  });

  @override
  State<PermissionRequestPage> createState() => _PermissionRequestPageState();
}

class _PermissionRequestPageState extends State<PermissionRequestPage> {
  final PermissionService _permissionService = PermissionService();
  Map<PermissionType, PermissionStatus> _permissions = {};
  bool _isChecking = true;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isChecking = true;
    });

    final permissions = await _permissionService.checkAllPermissions();
    
    setState(() {
      _permissions = permissions;
      _isChecking = false;
    });
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isRequesting = true;
    });

    final results = await _permissionService.requestAllPermissions();
    
    // 重新檢查權限狀態
    await _checkPermissions();

    setState(() {
      _isRequesting = false;
    });

    // 檢查是否還有未授予的權限
    final deniedPermissions = await _permissionService.getDeniedPermissions();
    final permanentlyDenied = await _permissionService.getPermanentlyDeniedPermissions();

    if (permanentlyDenied.isNotEmpty) {
      _showPermanentlyDeniedDialog(permanentlyDenied);
    } else if (deniedPermissions.isEmpty) {
      _showAllGrantedDialog();
    }
  }

  Future<void> _requestSinglePermission(PermissionType type) async {
    final success = await _permissionService.requestPermission(type);
    
    await _checkPermissions();

    if (!success) {
      final status = _permissions[type];
      if (status?.isPermanentlyDenied ?? false) {
        _showOpenSettingsDialog(type);
      }
    }
  }

  void _showPermanentlyDeniedDialog(List<PermissionStatus> permissions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('權限被永久拒絕'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下權限已被永久拒絕，請在設置中手動開啟：'),
            const SizedBox(height: 12),
            ...permissions.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${p.name}'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openAppSettings();
            },
            child: const Text('打開設置'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog(PermissionType type) {
    final permissionName = _permissions[type]?.name ?? '權限';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要權限'),
        content: Text('$permissionName 已被拒絕，請在設置中開啟。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openAppSettings();
            },
            child: const Text('打開設置'),
          ),
        ],
      ),
    );
  }

  void _showAllGrantedDialog() {
    AppPreferences.setPermissionsRequested();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('權限已授予'),
        content: const Text('所有必要權限已授予，應用可以正常使用。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(PermissionType type, PermissionStatus? status) {
    if (status == null) return const SizedBox();

    final isGranted = status.isGranted;
    final icon = _getPermissionIcon(type);
    final color = isGranted ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          status.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isGranted
              ? '已授予'
              : status.isPermanentlyDenied
                  ? '已永久拒絕，請在設置中開啟'
                  : '未授予',
        ),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.settings),
                onPressed: status.isPermanentlyDenied
                    ? () => _showOpenSettingsDialog(type)
                    : () => _requestSinglePermission(type),
              ),
      ),
    );
  }

  IconData _getPermissionIcon(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return Icons.camera_alt;
      case PermissionType.bluetooth:
        return Icons.bluetooth;
      case PermissionType.location:
        return Icons.location_on;
      case PermissionType.storage:
        return Icons.storage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deniedPermissions = _permissions.values
        .where((status) => !status.isGranted)
        .toList();
    final allGranted = deniedPermissions.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('權限管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 說明文字
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '應用需要以下權限才能正常運行：',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• 相機：用於拍照和掃描條碼'),
                      const Text('• 藍牙：用於連接打印機'),
                      const Text('• 位置：用於藍牙設備掃描（Android）'),
                      const Text('• 存儲：用於保存照片'),
                    ],
                  ),
                ),

                // 權限列表
                Expanded(
                  child: ListView(
                    children: _permissions.entries.map((entry) {
                      return _buildPermissionCard(entry.key, entry.value);
                    }).toList(),
                  ),
                ),

                // 底部按鈕
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (allGranted)
                        const Text(
                          '✓ 所有權限已授予',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isRequesting
                                ? null
                                : _requestAllPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isRequesting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    '請求所有權限',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context, allGranted),
                        child: Text(allGranted ? '完成' : '稍後設置'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

