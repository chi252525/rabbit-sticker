import 'dart:io';
import 'package:flutter/material.dart';
import 'pages/camera_page.dart';
import 'pages/bluetooth_page.dart';
import 'pages/canvas_page.dart';
import 'pages/permission_request_page.dart';
import 'pages/label_edit_page.dart';
import 'services/permission_service.dart';
import 'services/app_preferences.dart';
import 'services/app_state.dart';
import 'models/product_label.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'smart-sticker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PermissionCheckPage(),
    );
  }
}

class PermissionCheckPage extends StatefulWidget {
  const PermissionCheckPage({super.key});

  @override
  State<PermissionCheckPage> createState() => _PermissionCheckPageState();
}

class _PermissionCheckPageState extends State<PermissionCheckPage> {
  final PermissionService _permissionService = PermissionService();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndNavigate();
  }

  Future<void> _checkPermissionsAndNavigate() async {
    // 檢查是否是首次啟動
    final isFirstLaunch = await AppPreferences.isFirstLaunch();
    
    // 檢查權限狀態
    final deniedPermissions = await _permissionService.getDeniedPermissions();
    final hasDeniedPermissions = deniedPermissions.isNotEmpty;

    // 如果是首次啟動或有未授予的權限，顯示權限請求頁面
    if (isFirstLaunch || hasDeniedPermissions) {
      if (mounted) {
        final result = await Navigator.pushReplacement<bool, void>(
          context,
          MaterialPageRoute(
            builder: (context) => PermissionRequestPage(
              isFirstLaunch: isFirstLaunch,
            ),
          ),
        );

        // 標記已啟動
        await AppPreferences.setLaunched();
        
        // 如果權限已授予，標記已請求
        if (result == true) {
          await AppPreferences.setPermissionsRequested();
        }

        // 導航到主頁
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(
                title: '相機、藍牙與 Canvas 測試',
              ),
            ),
          );
        }
      }
    } else {
      // 所有權限已授予，直接進入主頁
      if (mounted) {
        await AppPreferences.setLaunched();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MyHomePage(
              title: '相機、藍牙與 Canvas 測試',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isChecking ? '正在檢查權限...' : '準備就緒',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
  }

  void _refreshLabels() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final labels = _appState.getAllLabels();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('smart-sticker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const PermissionRequestPage(
                    isFirstLaunch: false,
                  ),
                ),
              );
              if (result == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('權限已更新'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            tooltip: '權限管理',
          ),
        ],
      ),
      body: Column(
        children: [
          // AI 標籤列表標題
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.label, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'AI 標籤列表 (${labels.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 標籤列表
          Expanded(
            child: labels.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暫無標籤',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '點擊下方按鈕開始拍照',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: labels.length,
                    itemBuilder: (context, index) {
                      final labelData = labels[index];
                      final label = labelData['label'] as ProductLabel;
                      final imagePath = labelData['imagePath'] as String;
                      final timestamp = labelData['timestamp'] as String;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: imagePath.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(imagePath),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.image, size: 40),
                          title: Text(
                            label.productName ?? '未命名商品',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (label.barcode != null)
                                Text('條碼: ${label.barcode}'),
                              if (label.price != null)
                                Text(
                                  '價格: ${label.price}',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LabelEditPage(
                                    imagePath: imagePath,
                                    initialLabel: label,
                                  ),
                                ),
                              ).then((_) => _refreshLabels());
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LabelEditPage(
                                  imagePath: imagePath,
                                  initialLabel: label,
                                ),
                              ),
                            ).then((_) => _refreshLabels());
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // 底部拍照按鈕
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraPage(),
            ),
          ).then((_) => _refreshLabels());
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('拍照'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
