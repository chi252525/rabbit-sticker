import 'dart:math' as math;
import 'package:flutter/material.dart';

class CanvasPage extends StatefulWidget {
  const CanvasPage({super.key});

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  final List<Offset> _points = [];
  Color _currentColor = Colors.blue;
  double _strokeWidth = 3.0;
  bool _isDrawing = false;

  // 繪製模式
  String _drawMode = '自由繪製';
  final List<String> _drawModes = [
    '自由繪製',
    '直線',
    '矩形',
    '圓形',
    '清除',
  ];

  Offset? _startPoint;
  Offset? _endPoint;

  void _clearCanvas() {
    setState(() {
      _points.clear();
      _startPoint = null;
      _endPoint = null;
    });
  }

  void _changeColor(Color color) {
    setState(() {
      _currentColor = color;
    });
  }

  void _changeStrokeWidth(double width) {
    setState(() {
      _strokeWidth = width;
    });
  }

  void _changeDrawMode(String mode) {
    setState(() {
      _drawMode = mode;
      if (mode == '清除') {
        _clearCanvas();
        _drawMode = '自由繪製';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas 繪製測試'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearCanvas,
            tooltip: '清除畫布',
          ),
        ],
      ),
      body: Column(
        children: [
          // 控制面板
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Column(
              children: [
                // 繪製模式選擇
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _drawModes.map((mode) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(mode),
                          selected: _drawMode == mode,
                          onSelected: (selected) {
                            if (selected) _changeDrawMode(mode);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // 顏色選擇
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('顏色: '),
                    ..._buildColorButtons(),
                  ],
                ),
                const SizedBox(height: 8),
                // 線條寬度
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('線寬: '),
                    Slider(
                      value: _strokeWidth,
                      min: 1.0,
                      max: 20.0,
                      divisions: 19,
                      label: _strokeWidth.round().toString(),
                      onChanged: (value) => _changeStrokeWidth(value),
                    ),
                    Text('${_strokeWidth.round()}'),
                  ],
                ),
              ],
            ),
          ),
          // Canvas 繪製區域
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _isDrawing = true;
                  _startPoint = details.localPosition;
                  _endPoint = details.localPosition;
                  if (_drawMode == '自由繪製') {
                    _points.add(details.localPosition);
                  }
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _endPoint = details.localPosition;
                  if (_drawMode == '自由繪製') {
                    _points.add(details.localPosition);
                  }
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _isDrawing = false;
                  if (_drawMode != '自由繪製' && _startPoint != null && _endPoint != null) {
                    // 保存形狀的起點和終點
                    _points.add(_startPoint!);
                    _points.add(_endPoint!);
                  }
                  _startPoint = null;
                  _endPoint = null;
                });
              },
              child: CustomPaint(
                painter: CanvasPainter(
                  points: _points,
                  currentColor: _currentColor,
                  strokeWidth: _strokeWidth,
                  drawMode: _drawMode,
                  startPoint: _startPoint,
                  endPoint: _endPoint,
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildColorButtons() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];

    return colors.map((color) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => _changeColor(color),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _currentColor == color ? Colors.black : Colors.grey,
                width: _currentColor == color ? 3 : 1,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class CanvasPainter extends CustomPainter {
  final List<Offset> points;
  final Color currentColor;
  final double strokeWidth;
  final String drawMode;
  final Offset? startPoint;
  final Offset? endPoint;

  CanvasPainter({
    required this.points,
    required this.currentColor,
    required this.strokeWidth,
    required this.drawMode,
    this.startPoint,
    this.endPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = currentColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (drawMode == '自由繪製') {
      // 自由繪製模式
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    } else if (drawMode == '直線' && startPoint != null && endPoint != null) {
      // 繪製直線
      canvas.drawLine(startPoint!, endPoint!, paint);
      // 繪製已保存的直線
      for (int i = 0; i < points.length - 1; i += 2) {
        if (i + 1 < points.length) {
          canvas.drawLine(points[i], points[i + 1], paint);
        }
      }
    } else if (drawMode == '矩形' && startPoint != null && endPoint != null) {
      // 繪製矩形
      final rect = Rect.fromPoints(startPoint!, endPoint!);
      canvas.drawRect(rect, paint);
      // 繪製已保存的矩形
      for (int i = 0; i < points.length - 1; i += 2) {
        if (i + 1 < points.length) {
          final savedRect = Rect.fromPoints(points[i], points[i + 1]);
          canvas.drawRect(savedRect, paint);
        }
      }
    } else if (drawMode == '圓形' && startPoint != null && endPoint != null) {
      // 繪製圓形
      final center = Offset(
        (startPoint!.dx + endPoint!.dx) / 2,
        (startPoint!.dy + endPoint!.dy) / 2,
      );
      final radius = math.sqrt(
        math.pow(startPoint!.dx - endPoint!.dx, 2) +
            math.pow(startPoint!.dy - endPoint!.dy, 2),
      ) / 2;
      canvas.drawCircle(center, radius, paint);
      // 繪製已保存的圓形
      for (int i = 0; i < points.length - 1; i += 2) {
        if (i + 1 < points.length) {
          final savedCenter = Offset(
            (points[i].dx + points[i + 1].dx) / 2,
            (points[i].dy + points[i + 1].dy) / 2,
          );
          final savedRadius = math.sqrt(
            math.pow(points[i].dx - points[i + 1].dx, 2) +
                math.pow(points[i].dy - points[i + 1].dy, 2),
          ) / 2;
          canvas.drawCircle(savedCenter, savedRadius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.drawMode != drawMode ||
        oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint;
  }
}

