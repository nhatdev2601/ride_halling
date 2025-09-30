# Hướng dẫn cấu hình Google Maps API

##  Lấy Google Maps API Key

### Bước 1: Truy cập Google Cloud Console
1. Đi đến [Google Cloud Console](https://console.cloud.google.com/)
2. Đăng nhập bằng tài khoản Google
3. Tạo project mới hoặc chọn project hiện có

### Bước 2: Kích hoạt Maps SDK
1. Vào **APIs & Services** > **Library**
2. Tìm và kích hoạt các API sau:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geolocation API

### Bước 3: Tạo API Key
1. Vào **APIs & Services** > **Credentials**
2. Nhấn **Create Credentials** > **API Key**
3. Sao chép API Key vừa tạo

### Bước 4: Hạn chế API Key (Khuyến nghị)
1. Nhấn vào API Key vừa tạo
2. Trong **Application restrictions**, chọn **Android apps**
3. Thêm **Package name**: `com.example.ride_hailing`
4. Thêm **SHA-1 certificate fingerprint** (xem cách lấy bên dưới)

##  Cấu hình Android

### Thay thế API Key trong AndroidManifest.xml
Mở file `android/app/src/main/AndroidManifest.xml` và thay thế:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

### Lấy SHA-1 Fingerprint
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore (khi có)
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

##  Cấu hình iOS

### Thêm API Key vào AppDelegate.swift
Mở file `ios/Runner/AppDelegate.swift` và thêm:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

##  Bảo mật API Key

### Sử dụng Environment Variables (Khuyến nghị)
1. Tạo file `.env` trong thư mục gốc:
```
GOOGLE_MAPS_API_KEY=your_actual_api_key_here
```

2. Thêm `.env` vào `.gitignore`:
```
.env
```

3. Sử dụng trong code:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load(fileName: ".env");
String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
```

##  Permissions cần thiết

### Android - `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS - `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show your position on the map.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track your rides.</string>
```

##  Kiểm tra cấu hình

### Test API Key
```dart
// Thêm vào initState() của HomeScreen
void _testMapLoading() {
  print('Testing Google Maps API...');
  // Nếu map hiển thị được thì API key đã hoạt động
}
```

### Debug thường gặp
1. **API key not found**: Kiểm tra AndroidManifest.xml
2. **API key invalid**: Kiểm tra restrictions và permissions
3. **Billing not enabled**: Kích hoạt billing trong Google Cloud Console

## Chi phí

- **Google Maps**: Miễn phí 28,500 map loads/tháng
- **Places API**: Miễn phí 2,500 requests/tháng
- **Directions API**: Miễn phí 2,500 requests/tháng

##  Chạy ứng dụng

Sau khi cấu hình xong:

```bash
flutter clean
flutter pub get
flutter run
```

##  Hỗ trợ

Nếu gặp vấn đề, kiểm tra:
1. [Google Maps Flutter Documentation](https://pub.dev/packages/google_maps_flutter)
2. [Google Cloud Console Logs](https://console.cloud.google.com/logs)
3. Flutter Debug Console để xem error messages

---

**Lưu ý**: Không commit API key lên repository public! Luôn sử dụng environment variables hoặc secret management.