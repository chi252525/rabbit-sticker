import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final MyBluetoothService _bluetoothService = MyBluetoothService();
  bool _isInitialized = false;
  String _statusMessage = '準備就緒';
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    setState(() {
      _statusMessage = '正在初始化藍牙...';
    });

    final success = await _bluetoothService.initialize();
    if (success) {
      setState(() {
        _isInitialized = true;
        _statusMessage = '藍牙服務已初始化';
      });
      _checkBluetoothState();
    } else {
      setState(() {
        _statusMessage = '藍牙初始化失敗，請檢查權限';
      });
    }
  }

  Future<void> _checkBluetoothState() async {
    final isEnabled = await _bluetoothService.isBluetoothEnabled();
    if (!isEnabled) {
      setState(() {
        _statusMessage = '藍牙未開啟，請先開啟藍牙';
      });
    } else {
      setState(() {
        _statusMessage = '藍牙已開啟，可以開始掃描';
      });
    }
  }

  Future<void> _turnOnBluetooth() async {
    await _bluetoothService.turnOnBluetooth();
    await Future.delayed(const Duration(seconds: 1));
    _checkBluetoothState();
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
      _statusMessage = '正在掃描設備...';
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
        _statusMessage = '開始掃描失敗';
      });
    }
  }

  Future<void> _stopScan() async {
    await _bluetoothService.stopScan();
    setState(() {
      _statusMessage = '掃描已停止';
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _statusMessage = '正在連接設備: ${device.name}...';
    });

    final success = await _bluetoothService.connectToDevice(device);
    if (success) {
      setState(() {
        _selectedDevice = device;
        _statusMessage = '已連接到: ${device.name}';
      });
    } else {
      setState(() {
        _statusMessage = '連接失敗';
      });
    }
  }

  Future<void> _disconnect() async {
    await _bluetoothService.disconnect();
    setState(() {
      _selectedDevice = null;
      _statusMessage = '已斷開連接';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getAdapterStateText(BluetoothAdapterState state) {
    switch (state) {
      case BluetoothAdapterState.on:
        return '開啟';
      case BluetoothAdapterState.off:
        return '關閉';
      case BluetoothAdapterState.turningOn:
        return '正在開啟';
      case BluetoothAdapterState.turningOff:
        return '正在關閉';
      default:
        return '未知';
    }
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('藍牙測試'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 狀態資訊
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '藍牙狀態: ${_getAdapterStateText(_bluetoothService.adapterState)}',
                  style: const TextStyle(fontSize: 12),
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
                  onPressed: _isInitialized ? _turnOnBluetooth : null,
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('開啟藍牙'),
                ),
                ElevatedButton.icon(
                  onPressed: _isInitialized && !_bluetoothService.isScanning
                      ? _startScan
                      : null,
                  icon: const Icon(Icons.search),
                  label: const Text('掃描設備'),
                ),
                ElevatedButton.icon(
                  onPressed: _bluetoothService.isScanning ? _stopScan : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止掃描'),
                ),
              ],
            ),
          ),

          // 已連接設備資訊
          if (_selectedDevice != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '已連接: ${_selectedDevice!.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _disconnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('斷開'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('設備ID: ${_selectedDevice!.remoteId}'),
                  if (_bluetoothService.services.isNotEmpty)
                    Text(
                        '服務數量: ${_bluetoothService.services.length}'),
                ],
              ),
            ),

          // 設備列表
          Expanded(
            child: _bluetoothService.discoveredDevices.isEmpty
                ? const Center(
                    child: Text('未發現設備，請點擊掃描按鈕'),
                  )
                : ListView.builder(
                    itemCount: _bluetoothService.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device =
                          _bluetoothService.discoveredDevices[index];
                      final isConnected =
                          _selectedDevice?.remoteId == device.remoteId;

                      return ListTile(
                        leading: Icon(
                          isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                          color: isConnected ? Colors.green : Colors.grey,
                        ),
                        title: Text(device.name.isEmpty
                            ? '未知設備'
                            : device.name),
                        subtitle: Text(device.remoteId.toString()),
                        trailing: isConnected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : ElevatedButton(
                                onPressed: () => _connectToDevice(device),
                                child: const Text('連接'),
                              ),
                        onTap: isConnected ? null : () => _connectToDevice(device),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

