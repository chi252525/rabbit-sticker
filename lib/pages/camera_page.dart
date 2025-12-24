import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/ai_service.dart';
import '../models/product_label.dart';
import 'label_edit_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  final AIService _aiService = AIService();
  String? _capturedImagePath;
  String? _recordedVideoPath;
  bool _isInitializing = false;
  bool _isAnalyzing = false;
  String _statusMessage = '準備就緒';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = '正在初始化相機...';
    });

    final success = await _cameraService.initialize();
    if (success) {
      setState(() {
        _isInitializing = false;
        _statusMessage = '相機已就緒';
      });
    } else {
      setState(() {
        _isInitializing = false;
        _statusMessage = '相機初始化失敗，請檢查權限';
      });
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraService.isInitialized) {
      _showMessage('相機未初始化');
      return;
    }

    setState(() {
      _statusMessage = '正在拍照...';
    });

    final path = await _cameraService.takePicture();
    if (path != null) {
      setState(() {
        _capturedImagePath = path;
        _statusMessage = '拍照成功，正在分析圖片...';
        _isAnalyzing = true;
      });

      // 調用 AI 服務分析圖片
      try {
        final label = await _aiService.analyzeImage(path);
        
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _statusMessage = '分析完成';
          });

          // 跳轉到標籤編輯頁面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LabelEditPage(
                imagePath: path,
                initialLabel: label,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _statusMessage = '分析失敗: $e';
          });
          _showMessage('AI 分析失敗，請重試');
        }
      }
    } else {
      setState(() {
        _statusMessage = '拍照失敗';
      });
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_cameraService.isInitialized) {
      _showMessage('相機未初始化');
      return;
    }

    final success = await _cameraService.startVideoRecording();
    if (success) {
      setState(() {
        _statusMessage = '正在錄影...';
      });
    } else {
      setState(() {
        _statusMessage = '開始錄影失敗';
      });
    }
  }

  Future<void> _stopVideoRecording() async {
    final path = await _cameraService.stopVideoRecording();
    if (path != null) {
      setState(() {
        _recordedVideoPath = path;
        _statusMessage = '錄影完成: $path';
      });
    } else {
      setState(() {
        _statusMessage = '停止錄影失敗';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (!_cameraService.isInitialized) {
      _showMessage('相機未初始化');
      return;
    }

    setState(() {
      _statusMessage = '正在切換相機...';
    });

    final success = await _cameraService.switchCamera();
    if (success) {
      setState(() {
        _statusMessage = '相機切換成功';
      });
    } else {
      setState(() {
        _statusMessage = '相機切換失敗';
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 相機預覽（全屏）
          Expanded(
            child: Stack(
              children: [
                _isInitializing
                    ? const Center(child: CircularProgressIndicator())
                    : _cameraService.isInitialized &&
                            _cameraService.controller != null
                        ? CameraPreview(_cameraService.controller!)
                        : const Center(
                            child: Text('相機未初始化'),
                          ),
                // AI 分析中覆蓋層
                if (_isAnalyzing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'AI 正在分析圖片...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 拍照按鈕（固定在底部中央）
          Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: FloatingActionButton(
                onPressed: _cameraService.isInitialized && !_isAnalyzing
                    ? _takePicture
                    : null,
                backgroundColor: Colors.blue,
                child: _isAnalyzing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.camera_alt, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

