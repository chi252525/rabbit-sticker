# Smart Sticker

一個基於 Flutter 開發的智能標籤管理與打印應用，整合 AI 圖像識別、標籤模板設計和藍牙打印功能。

## 📱 應用簡介

Smart Sticker 是一款專為商品標籤管理設計的移動應用，通過 AI 技術自動識別商品信息（商品名稱、條碼、價格），並支持自定義標籤模板和藍牙打印功能。

## ✨ 核心功能

### 1. 📸 智能拍照識別
- **相機拍照**：全屏相機預覽，一鍵拍照
- **AI 圖像識別**：自動識別商品信息
  - 商品名稱
  - 條碼（EAN-13）
  - 價格信息
- **信心度顯示**：顯示 AI 識別的可信度

### 2. 🏷️ 標籤編輯與管理
- **AI 建議標籤**：顯示 AI 識別的標籤內容
- **手動編輯**：可編輯商品名稱、條碼、價格
- **標籤列表**：查看所有已保存的標籤
- **標籤預覽**：實時預覽標籤效果

### 3. 🎨 標籤模板系統
- **尺寸選擇**：小、中、大三種尺寸
- **樣式選擇**：
  - 僅文字
  - 文字 + 條碼
  - 僅條碼
- **即時預覽**：選擇模板後立即預覽效果
- **9 種預設模板**：涵蓋各種尺寸和樣式組合

### 4. 🖨️ 藍牙打印
- **BLE 掃描**：自動掃描附近的藍牙打印機
- **設備連接**：選擇並連接打印機
- **ESC/POS 協議支持**：兼容主流標籤打印機
- **打印狀態追蹤**：實時顯示連接和打印狀態
- **模板預覽**：打印前預覽標籤內容

### 5. 🎨 Canvas 繪製
- **自由繪製**：手指滑動繪製
- **形狀繪製**：直線、矩形、圓形
- **顏色選擇**：8 種預設顏色
- **線條寬度調整**：1-20px 可調

### 6. 🔐 權限管理
- **統一權限管理**：相機、藍牙、位置、存儲權限
- **智能權限請求**：首次啟動自動請求權限
- **權限狀態顯示**：清晰顯示各權限狀態
- **永久拒絕處理**：引導用戶到系統設置開啟權限

## 🏗️ 技術架構

### 技術棧
- **框架**：Flutter 3.13.7
- **語言**：Dart 3.1.3
- **狀態管理**：StatefulWidget + 單例模式
- **UI 框架**：Material Design 3

### 核心依賴
```yaml
camera: ^0.10.5+9              # 相機功能
flutter_blue_plus: ^1.32.0     # 藍牙通信
permission_handler: ^11.0.1    # 權限管理
barcode_widget: ^2.0.3         # 條碼生成
path_provider: ^2.1.2          # 文件路徑
shared_preferences: ^2.2.2     # 本地存儲
```

## 📋 功能流程

### 完整工作流程

```
┌─────────────┐
│   Home 頁面 │
│  - 標籤列表 │
│  - 拍照按鈕 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   拍照頁面  │
│ Camera Preview│
│  + 拍照按鈕 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  AI 分析中  │
│  (自動處理) │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ AI 標籤頁面 │
│ 步驟 1: AI 建議│
│ 步驟 2: 編輯標籤│
│ 步驟 3: 選模板│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   打印頁面  │
│ 模板預覽    │
│ 藍牙掃描列表│
│ 打印按鈕    │
└─────────────┘
```

### 詳細步驟說明

#### 1. 拍照流程
1. 點擊首頁底部「拍照」按鈕
2. 進入全屏相機預覽界面
3. 點擊中央拍照按鈕
4. AI 自動分析圖片（顯示進度）
5. 自動跳轉到標籤編輯頁面

#### 2. 標籤編輯流程
1. **查看 AI 建議**：查看 AI 識別的標籤信息
2. **編輯標籤**：手動修改商品名稱、條碼、價格
3. **選擇模板**：
   - 點擊「選擇標籤模板」
   - 瀏覽 9 種預設模板
   - 即時預覽標籤效果
   - 確認選擇
4. **保存標籤**：點擊保存按鈕，標籤存入應用狀態

#### 3. 打印流程
1. 在標籤編輯頁面點擊「藍牙打印標籤」
2. 查看標籤預覽（頂部）
3. 點擊「掃描」按鈕搜索打印機
4. 選擇要連接的打印機
5. 點擊「連接」建立連接
6. 連接成功後點擊「打印」按鈕
7. 等待打印完成，查看打印狀態

## 📁 項目結構

```
lib/
├── main.dart                    # 應用入口，主頁面
├── models/                      # 數據模型
│   ├── product_label.dart      # 商品標籤模型
│   └── label_template.dart     # 標籤模板模型
├── services/                    # 服務層
│   ├── camera_service.dart     # 相機服務
│   ├── bluetooth_service.dart   # 藍牙服務
│   ├── print_service.dart      # 打印服務
│   ├── ai_service.dart         # AI 識別服務（待實作）
│   ├── permission_service.dart # 權限管理服務
│   ├── app_state.dart          # 應用狀態管理
│   └── app_preferences.dart    # 應用偏好設置
├── pages/                       # 頁面
│   ├── camera_page.dart        # 拍照頁面
│   ├── label_edit_page.dart    # 標籤編輯頁面
│   ├── template_selection_page.dart  # 模板選擇頁面
│   ├── printer_selection_page.dart   # 打印機選擇頁面
│   ├── permission_request_page.dart  # 權限請求頁面
│   ├── bluetooth_page.dart     # 藍牙測試頁面
│   └── canvas_page.dart        # Canvas 繪製頁面
└── widgets/                     # 組件
    └── label_preview.dart       # 標籤預覽組件
```

## 🚀 快速開始

### 環境要求
- Flutter SDK >= 3.1.3
- Dart SDK >= 3.1.3
- Android Studio / Xcode（用於構建）
- Java 17+（Android 開發）

### 安裝步驟

1. **克隆項目**
   ```bash
   git clone <repository-url>
   cd smart-sticker
   ```

2. **安裝依賴**
   ```bash
   flutter pub get
   ```

3. **運行應用**
   ```bash
   flutter run
   ```

### 構建發布版本

**Android:**
```bash
flutter build apk --release
# 或
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## ⚙️ 配置說明

### Android 配置

**權限配置** (`android/app/src/main/AndroidManifest.xml`)
- 相機權限
- 藍牙權限（包括掃描、連接、廣播）
- 位置權限（藍牙掃描需要）
- 存儲權限

**Gradle 配置**
- Gradle 8.3
- Android Gradle Plugin 8.1.0
- minSdkVersion: 21
- compileSdkVersion: 34
- Java 17

### iOS 配置

**權限配置** (`ios/Runner/Info.plist`)
- NSCameraUsageDescription
- NSMicrophoneUsageDescription
- NSPhotoLibraryUsageDescription
- NSBluetoothAlwaysUsageDescription

## 🔧 開發指南

### AI API 集成（待實作）

AI 服務位於 `lib/services/ai_service.dart`，需要實作以下方法：

```dart
Future<ProductLabel> analyzeImage(String imagePath) async {
  // TODO: 實作上傳圖片到 AI API
  // 1. 讀取圖片文件
  // 2. 轉換為 base64 或直接上傳
  // 3. 調用 AI API（OpenAI Vision, Google Vision 等）
  // 4. 解析返回的 JSON 數據
  // 5. 提取商品名稱、條碼、價格等信息
}
```

**建議的 AI API：**
- OpenAI Vision API
- Google Cloud Vision API
- 自定義 OCR + NLP 服務

### 打印機兼容性

應用支持 ESC/POS 協議的藍牙打印機，常見品牌：
- 熱敏打印機
- 標籤打印機
- 小票打印機

### 測試場景

1. **首次啟動**：自動顯示權限請求頁面
2. **第二次啟動**：檢查權限狀態，如有未授予則提示
3. **拒絕權限**：顯示權限狀態，引導用戶開啟

## 📱 平台支持

- ✅ Android (minSdkVersion: 21)
- ✅ iOS (11.0+)
- ✅ macOS
- ⚠️ Web（部分功能受限）
- ⚠️ Windows（部分功能受限）
- ⚠️ Linux（部分功能受限）

## 🐛 已知問題

- AI API 集成待實作（目前返回模擬數據）
- 圖片打印功能待完善（目前使用文字模式）

## 📝 更新日誌

### v1.0.0 (2025-01-XX)
- ✨ 初始版本發布
- ✨ 相機拍照功能
- ✨ AI 標籤識別（模擬）
- ✨ 標籤模板系統
- ✨ 藍牙打印功能
- ✨ 權限管理系統
- ✨ Canvas 繪製功能

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

## 📄 許可證

此項目為私有項目，未開源。

## 👥 開發團隊

- 開發者：Becky Yeh

## 📞 聯繫方式

如有問題或建議，請通過以下方式聯繫：
- Issue: [GitHub Issues](https://github.com/your-repo/issues)

---

**注意**：此應用需要相機和藍牙權限才能正常使用。首次啟動時會自動請求必要權限。
