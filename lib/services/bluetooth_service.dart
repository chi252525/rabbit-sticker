import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class MyBluetoothService {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  List<BluetoothDevice> _discoveredDevices = [];
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  BluetoothAdapterState get adapterState => _adapterState;
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothService> get services => _services;
  bool get isScanning => _scanSubscription != null;

  /// 初始化藍牙服務
  Future<bool> initialize() async {
    try {
      // 請求藍牙權限
      if (Platform.isAndroid) {
        final status = await Permission.bluetoothScan.request();
        if (!status.isGranted) {
          return false;
        }
      }

      // 監聽適配器狀態
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        _adapterState = state;
      });

      // 獲取當前狀態
      _adapterState = await FlutterBluePlus.adapterState.first;

      return true;
    } catch (e) {
      print('Bluetooth initialization error: $e');
      return false;
    }
  }

  /// 檢查藍牙是否開啟
  Future<bool> isBluetoothEnabled() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  /// 開啟藍牙（Android）
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      print('Turn on Bluetooth error: $e');
    }
  }

  /// 開始掃描設備
  Future<bool> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (isScanning) {
      return false;
    }

    try {
      _discoveredDevices.clear();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          if (!_discoveredDevices.contains(result.device)) {
            _discoveredDevices.add(result.device);
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: timeout);
      return true;
    } catch (e) {
      print('Start scan error: $e');
      return false;
    }
  }

  /// 停止掃描
  Future<void> stopScan() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Stop scan error: $e');
    }
  }

  /// 連接設備
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _connectedDevice = device;

      // 發現服務
      final discoveredServices = await device.discoverServices();
      _services = discoveredServices;

      // 監聽連接狀態
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _services.clear();
        }
      });

      return true;
    } catch (e) {
      print('Connect to device error: $e');
      return false;
    }
  }

  /// 斷開連接
  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
      _connectedDevice = null;
      _services.clear();
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  /// 讀取特徵值
  Future<List<int>?> readCharacteristic(
    BluetoothCharacteristic characteristic,
  ) async {
    try {
      return await characteristic.read();
    } catch (e) {
      print('Read characteristic error: $e');
      return null;
    }
  }

  /// 寫入特徵值
  Future<bool> writeCharacteristic(
    BluetoothCharacteristic characteristic,
    List<int> value, {
    bool withoutResponse = false,
  }) async {
    try {
      await characteristic.write(
        value,
        withoutResponse: withoutResponse,
      );
      return true;
    } catch (e) {
      print('Write characteristic error: $e');
      return false;
    }
  }

  /// 訂閱通知
  Stream<List<int>>? subscribeToCharacteristic(
    BluetoothCharacteristic characteristic,
  ) {
    try {
      characteristic.setNotifyValue(true);
      return characteristic.onValueReceived;
    } catch (e) {
      print('Subscribe to characteristic error: $e');
      return null;
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    await stopScan();
    await disconnect();
    await _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}

