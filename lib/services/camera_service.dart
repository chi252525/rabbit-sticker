import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  List<CameraDescription>? get cameras => _cameras;

  /// 初始化相機服務
  Future<bool> initialize() async {
    try {
      // 請求相機權限
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return false;
      }

      // 獲取可用相機列表
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // 初始化相機控制器（使用後置相機）
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Camera initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// 切換前後相機
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return false;
    }

    try {
      final currentIndex = _cameras!.indexOf(_controller!.description);
      final newIndex = (currentIndex + 1) % _cameras!.length;

      await _controller!.dispose();
      _controller = CameraController(
        _cameras![newIndex],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      return true;
    } catch (e) {
      print('Switch camera error: $e');
      return false;
    }
  }

  /// 拍照
  Future<String?> takePicture() async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      return image.path;
    } catch (e) {
      print('Take picture error: $e');
      return null;
    }
  }

  /// 開始錄影
  Future<bool> startVideoRecording() async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return false;
    }

    if (_isRecording) {
      return false;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      return true;
    } catch (e) {
      print('Start video recording error: $e');
      return false;
    }
  }

  /// 停止錄影
  Future<String?> stopVideoRecording() async {
    if (!_isRecording || _controller == null) {
      return null;
    }

    try {
      final XFile video = await _controller!.stopVideoRecording();
      _isRecording = false;
      return video.path;
    } catch (e) {
      print('Stop video recording error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    _isRecording = false;
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}

