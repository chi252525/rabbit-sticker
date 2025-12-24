import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_label.dart';
import '../models/label_template.dart';
import '../services/app_state.dart';
import '../widgets/label_preview.dart';
import 'canvas_page.dart';
import 'template_selection_page.dart';
import 'printer_selection_page.dart';

class LabelEditPage extends StatefulWidget {
  final String imagePath;
  final ProductLabel initialLabel;

  const LabelEditPage({
    super.key,
    required this.imagePath,
    required this.initialLabel,
  });

  @override
  State<LabelEditPage> createState() => _LabelEditPageState();
}

class _LabelEditPageState extends State<LabelEditPage> {
  late ProductLabel _currentLabel;
  LabelTemplate? _selectedTemplate;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentLabel = widget.initialLabel;
    _productNameController.text = _currentLabel.productName ?? '';
    _barcodeController.text = _currentLabel.barcode ?? '';
    _priceController.text = _currentLabel.price ?? '';
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _updateLabel() {
    setState(() {
      _currentLabel = ProductLabel(
        productName: _productNameController.text.isEmpty
            ? null
            : _productNameController.text,
        barcode: _barcodeController.text.isEmpty
            ? null
            : _barcodeController.text,
        price: _priceController.text.isEmpty
            ? null
            : _priceController.text,
        confidence: _currentLabel.confidence,
      );
    });
  }

  void _saveLabel() {
    _updateLabel();
    // 保存標籤到 App 狀態
    AppState().addLabel(widget.imagePath, _currentLabel);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('標籤已保存'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openPrinterSelection() {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先選擇標籤模板'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterSelectionPage(
          label: _currentLabel,
          template: _selectedTemplate!,
        ),
      ),
    );
  }

  void _openCanvasEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CanvasPage(),
      ),
    );
  }

  Future<void> _selectTemplate() async {
    final template = await Navigator.push<LabelTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateSelectionPage(
          label: _currentLabel,
        ),
      ),
    );

    if (template != null) {
      setState(() {
        _selectedTemplate = template;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 標籤編輯'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLabel,
            tooltip: '保存標籤',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拍攝的圖片預覽
            Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // AI 建議標籤標題
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'AI 建議標籤',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentLabel.confidence != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: Text(
                        '信心度: ${(_currentLabel.confidence! * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[100],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 商品名稱輸入
            TextField(
              controller: _productNameController,
              decoration: InputDecoration(
                labelText: '商品名稱',
                hintText: '輸入商品名稱',
                prefixIcon: const Icon(Icons.shopping_bag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) => _updateLabel(),
            ),
            const SizedBox(height: 16),

            // 條碼輸入
            TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: '條碼',
                hintText: '輸入條碼',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateLabel(),
            ),
            const SizedBox(height: 16),

            // 價格輸入
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: '價格',
                hintText: '輸入價格',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateLabel(),
            ),
            const SizedBox(height: 24),

            // 步驟指示器
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStepIndicator(1, 'AI 建議', true),
                  const Icon(Icons.arrow_forward, color: Colors.blue),
                  _buildStepIndicator(2, '編輯', true),
                  const Icon(Icons.arrow_forward, color: Colors.blue),
                  _buildStepIndicator(3, '選模板', _selectedTemplate != null),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 標籤模板選擇
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectTemplate,
                icon: const Icon(Icons.style),
                label: Text(_selectedTemplate == null
                    ? '步驟 3: 選擇標籤模板'
                    : '更換標籤模板'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 標籤預覽（如果已選擇模板）
            if (_selectedTemplate != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '標籤預覽',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: LabelPreview(
                        label: _currentLabel,
                        template: _selectedTemplate!,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 藍牙打印按鈕（只有選擇模板後才顯示）
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openPrinterSelection,
                  icon: const Icon(Icons.print),
                  label: const Text('藍牙打印標籤'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 標籤預覽
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '標籤預覽',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_currentLabel.productName != null)
                    _buildLabelItem('商品名稱', _currentLabel.productName!),
                  if (_currentLabel.barcode != null)
                    _buildLabelItem('條碼', _currentLabel.barcode!),
                  if (_currentLabel.price != null)
                    _buildLabelItem('價格', _currentLabel.price!),
                  if (_currentLabel.isEmpty)
                    const Text(
                      '暫無標籤信息',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isCompleted ? Colors.blue : Colors.grey[600],
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

