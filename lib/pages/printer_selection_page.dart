import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart';
import '../services/print_service.dart';
import '../models/product_label.dart';
import '../models/label_template.dart';
import '../widgets/label_preview.dart';

class PrinterSelectionPage extends StatefulWidget {
  final ProductLabel label;
  final LabelTemplate template;

  const PrinterSelectionPage({
    super.key,
    required this.label,
    required this.template,
  });

  @override
  State<PrinterSelectionPage> createState() => _PrinterSelectionPageState();
}

class _PrinterSelectionPageState extends State<PrinterSelectionPage> {
  final MyBluetoothService _bluetoothService = MyBluetoothService();
  final PrintService _printService = PrintService();
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  String _statusMessage = '準備就緒';
  StreamSubscription<PrintStatus>? _printStatusSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
    _listenToPrintStatus();
  }

  Future<void> _initializeBluetooth() async {
    setState(() {
      _statusMessage = '正在初始化藍牙...';
    });

    final success = await _bluetoothService.initialize();
    if (success) {
      setState(() {
        _isInitialized = true;
        _statusMessage = '藍牙已就緒';
      });
    } else {
      setState(() {
        _statusMessage = '藍牙初始化失敗';
      });
    }
  }

  void _listenToPrintStatus() {
    _printStatusSubscription = _printService.statusStream?.listen((status) {
      setState(() {
        switch (status) {
          case PrintStatus.connecting:
            _statusMessage = '正在連接打印機...';
            _isConnecting = true;
            break;
          case PrintStatus.connected:
            _statusMessage = '已連接到打印機';
            _isConnecting = false;
            break;
          case PrintStatus.printing:
            _statusMessage = '正在打印...';
            break;
          case PrintStatus.success:
            _statusMessage = '打印成功！';
            _showSuccessDialog();
            break;
          case PrintStatus.failed:
            _statusMessage = '打印失敗';
            _isConnecting = false;
            break;
          case PrintStatus.disconnected:
            _statusMessage = '打印機已斷開連接';
            _isConnecting = false;
            break;
          default:
            break;
        }
      });
    });
  }

  Future<void> _startScan() async {
    if (!_isInitialized) {
      _showMessage('藍牙未初始化');
      return;
    }

    final isEnabled = await _bluetoothService.isBluetoothEnabled();
    if (!isEnabled) {
      _showMessage('請先開啟藍牙');
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = '正在掃描打印機...';
    });

    final success = await _bluetoothService.startScan();
    if (success) {
      setState(() {
        _statusMessage = '掃描中...';
      });

      // 10秒後自動停止掃描
      Future.delayed(const Duration(seconds: 10), () {
        _stopScan();
      });
    } else {
      setState(() {
        _isScanning = false;
        _statusMessage = '開始掃描失敗';
      });
    }
  }

  Future<void> _stopScan() async {
    await _bluetoothService.stopScan();
    setState(() {
      _isScanning = false;
      _statusMessage = '掃描已停止';
    });
  }

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = '正在連接: ${device.name}...';
    });

    final success = await _printService.connectToPrinter(device);
    if (success) {
      setState(() {
        _statusMessage = '已連接到: ${device.name}';
      });
    } else {
      setState(() {
        _isConnecting = false;
        _statusMessage = '連接失敗';
      });
    }
  }

  Future<void> _printLabel() async {
    if (_printService.connectedDevice == null) {
      _showMessage('請先連接打印機');
      return;
    }

    final success = await _printService.printLabel(
      widget.label,
      widget.template,
    );

    if (!success) {
      _showMessage('打印失敗');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('打印成功'),
        content: const Text('標籤已成功發送到打印機'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _printStatusSubscription?.cancel();
    _printService.dispose();
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('藍牙打印'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 模板預覽區域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                const Text(
                  '標籤預覽',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: LabelPreview(
                    label: widget.label,
                    template: widget.template,
                  ),
                ),
              ],
            ),
          ),

          // 狀態信息
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getStatusColor(),
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_printService.connectedDevice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '已連接: ${_printService.connectedDevice!.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 控制按鈕
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isInitialized && !_isScanning
                      ? _startScan
                      : null,
                  icon: const Icon(Icons.search),
                  label: const Text('掃描'),
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? _stopScan : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                ),
                if (_printService.connectedDevice != null)
                  ElevatedButton.icon(
                    onPressed: _isConnecting ? null : _printLabel,
                    icon: const Icon(Icons.print),
                    label: const Text('打印'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          // 藍牙掃描列表標題
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                const Icon(Icons.bluetooth, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '可用打印機',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 設備列表
          Expanded(
            child: _bluetoothService.discoveredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '未發現打印機',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '請點擊掃描按鈕搜索附近設備',
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
                    itemCount: _bluetoothService.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device =
                          _bluetoothService.discoveredDevices[index];
                      final isConnected =
                          _printService.connectedDevice?.remoteId ==
                              device.remoteId;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Icon(
                            isConnected
                                ? Icons.print
                                : Icons.bluetooth_searching,
                            color: isConnected ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                          title: Text(
                            device.name.isEmpty ? '未知設備' : device.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(device.remoteId.toString()),
                          trailing: isConnected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : ElevatedButton(
                                  onPressed: _isConnecting
                                      ? null
                                      : () => _connectToPrinter(device),
                                  child: const Text('連接'),
                                ),
                          onTap: isConnected || _isConnecting
                              ? null
                              : () => _connectToPrinter(device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_printService.status) {
      case PrintStatus.connected:
        return Colors.green;
      case PrintStatus.printing:
        return Colors.blue;
      case PrintStatus.success:
        return Colors.green;
      case PrintStatus.failed:
        return Colors.red;
      case PrintStatus.connecting:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

