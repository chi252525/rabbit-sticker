import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/product_label.dart';
import '../models/label_template.dart';

enum PrintStatus {
  idle,
  connecting,
  connected,
  printing,
  success,
  failed,
  disconnected,
}

class PrintService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _printCharacteristic;
  PrintStatus _status = PrintStatus.idle;
  String _statusMessage = '準備就緒';
  StreamController<PrintStatus>? _statusController;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  PrintStatus get status => _status;
  String get statusMessage => _statusMessage;
  Stream<PrintStatus>? get statusStream => _statusController?.stream;

  PrintService() {
    _statusController = StreamController<PrintStatus>.broadcast();
  }

  /// 連接藍牙打印機
  Future<bool> connectToPrinter(BluetoothDevice device) async {
    try {
      _updateStatus(PrintStatus.connecting, '正在連接打印機...');
      
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _connectedDevice = device;

      // 發現服務
      final services = await device.discoverServices();
      
      // 查找打印服務（通常是 ESC/POS 協議）
      BluetoothService? printService;
      for (var service in services) {
        // ESC/POS 服務 UUID: 000018f0-0000-1000-8000-00805f9b34fb
        // 或常見的串口服務: 00001101-0000-1000-8000-00805f9b34fb
        if (service.uuid.toString().toLowerCase().contains('18f0') ||
            service.uuid.toString().toLowerCase().contains('1101')) {
          printService = service;
          break;
        }
      }

      if (printService == null && services.isNotEmpty) {
        // 如果找不到特定服務，使用第一個服務
        printService = services.first;
      }

      if (printService != null) {
        // 查找可寫入的特徵值
        for (var characteristic in printService.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _printCharacteristic = characteristic;
            break;
          }
        }

        if (_printCharacteristic == null && printService.characteristics.isNotEmpty) {
          _printCharacteristic = printService.characteristics.first;
        }
      }

      // 監聽連接狀態
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _updateStatus(PrintStatus.disconnected, '打印機已斷開連接');
          _connectedDevice = null;
          _printCharacteristic = null;
        }
      });

      _updateStatus(PrintStatus.connected, '已連接到打印機');
      return true;
    } catch (e) {
      _updateStatus(PrintStatus.failed, '連接失敗: $e');
      return false;
    }
  }

  /// 斷開連接
  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
      _connectedDevice = null;
      _printCharacteristic = null;
      _updateStatus(PrintStatus.idle, '已斷開連接');
    } catch (e) {
      _updateStatus(PrintStatus.failed, '斷開連接失敗: $e');
    }
  }

  /// 發送標籤內容進行打印
  Future<bool> printLabel(
    ProductLabel label,
    LabelTemplate template,
  ) async {
    if (_connectedDevice == null || _printCharacteristic == null) {
      _updateStatus(PrintStatus.failed, '未連接到打印機');
      return false;
    }

    try {
      _updateStatus(PrintStatus.printing, '正在打印...');

      // 構建打印數據
      final printData = _buildPrintData(label, template);

      // 發送打印數據
      await _printCharacteristic!.write(
        printData,
        withoutResponse: false,
      );

      // 等待打印完成（模擬）
      await Future.delayed(const Duration(seconds: 2));

      _updateStatus(PrintStatus.success, '打印成功');
      return true;
    } catch (e) {
      _updateStatus(PrintStatus.failed, '打印失敗: $e');
      return false;
    }
  }

  /// 將標籤轉換為圖片並打印
  Future<bool> printLabelAsImage(
    ProductLabel label,
    LabelTemplate template,
  ) async {
    if (_connectedDevice == null || _printCharacteristic == null) {
      _updateStatus(PrintStatus.failed, '未連接到打印機');
      return false;
    }

    try {
      _updateStatus(PrintStatus.printing, '正在生成圖片並打印...');

      // TODO: 將標籤渲染為圖片
      // 1. 使用 RenderRepaintBoundary 或 screenshot 包
      // 2. 將圖片轉換為打印機格式（通常是黑白位圖）
      // 3. 發送圖片數據到打印機

      // 目前使用文字模式打印
      return await printLabel(label, template);
    } catch (e) {
      _updateStatus(PrintStatus.failed, '圖片打印失敗: $e');
      return false;
    }
  }

  /// 構建 ESC/POS 打印數據
  Uint8List _buildPrintData(ProductLabel label, LabelTemplate template) {
    final List<int> data = [];

    // ESC/POS 初始化
    data.addAll([0x1B, 0x40]); // ESC @ 初始化

    // 設置字符大小（根據模板尺寸）
    int charSize = 0;
    switch (template.size) {
      case LabelSize.small:
        charSize = 0; // 正常大小
        break;
      case LabelSize.medium:
        charSize = 0x11; // 雙倍寬度和高度
        break;
      case LabelSize.large:
        charSize = 0x33; // 三倍寬度和高度
        break;
    }
    data.addAll([0x1D, 0x21, charSize]); // GS ! 設置字符大小

    // 打印商品名稱
    if (label.productName != null && 
        (template.style == LabelStyle.textOnly || 
         template.style == LabelStyle.textWithBarcode)) {
      data.addAll(utf8.encode(label.productName!));
      data.add(0x0A); // 換行
    }

    // 打印價格
    if (label.price != null && 
        (template.style == LabelStyle.textOnly || 
         template.style == LabelStyle.textWithBarcode)) {
      data.addAll(utf8.encode(label.price!));
      data.add(0x0A); // 換行
    }

    // 打印條碼（如果模板包含條碼）
    if (label.barcode != null && 
        (template.style == LabelStyle.textWithBarcode || 
         template.style == LabelStyle.barcodeOnly)) {
      // ESC/POS 條碼打印
      data.addAll([0x1D, 0x6B, 0x04]); // GS k 選擇條碼類型 (EAN13)
      data.add(label.barcode!.length); // 條碼長度
      data.addAll(utf8.encode(label.barcode!));
      data.add(0x0A); // 換行
    }

    // 切紙（可選）
    data.addAll([0x1D, 0x56, 0x01]); // GS V 切紙

    return Uint8List.fromList(data);
  }

  void _updateStatus(PrintStatus newStatus, String message) {
    _status = newStatus;
    _statusMessage = message;
    _statusController?.add(newStatus);
  }

  void dispose() {
    disconnect();
    _statusController?.close();
    _statusController = null;
  }
}

