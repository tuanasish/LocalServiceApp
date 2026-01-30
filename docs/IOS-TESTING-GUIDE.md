# Hướng Dẫn Test iOS cho Chợ Quê MVP

## Tổng Quan

Có nhiều cách để test ứng dụng Flutter trên iOS, tùy thuộc vào môi trường của bạn.

---

## Cách 1: Test trên Mac với iOS Simulator (Khuyến nghị)

### Yêu cầu:
- Mac với macOS
- Xcode đã cài đặt
- Flutter SDK đã cài đặt

### Các bước:

#### 1. Kiểm tra Flutter setup cho iOS:
```bash
cd choque
flutter doctor -v
```

Đảm bảo có:
- ✅ Flutter (channel stable)
- ✅ Xcode - develop for iOS and macOS
- ✅ CocoaPods - version management tool

#### 2. Cài đặt CocoaPods dependencies:
```bash
cd ios
pod install
cd ..
```

#### 3. Mở iOS Simulator:
```bash
# Liệt kê các simulators có sẵn
xcrun simctl list devices

# Mở Simulator (chọn device phù hợp)
open -a Simulator
```

Hoặc từ Xcode: Xcode → Open Developer Tool → Simulator

#### 4. Chạy app trên Simulator:
```bash
# Chạy trên simulator mặc định
flutter run -d ios

# Hoặc chọn simulator cụ thể
flutter devices  # Xem danh sách devices
flutter run -d "iPhone 15 Pro"  # Chạy trên iPhone 15 Pro
```

#### 5. Test các tính năng:
- ✅ Đăng nhập/Đăng ký
- ✅ Tạo đơn hàng
- ✅ Xem đơn hàng
- ✅ Location permissions (cần grant trong Simulator)
- ✅ Phone calls (sẽ mở dialer)
- ✅ Image picker (cần chọn ảnh từ Simulator)
- ✅ Push notifications (cần cấu hình Firebase)

---

## Cách 2: Test trên Thiết Bị iOS Thật

### Yêu cầu:
- Mac với Xcode
- iPhone/iPad
- Apple Developer Account (free hoặc paid)
- USB cable để kết nối

### Các bước:

#### 1. Cấu hình Signing trong Xcode:
```bash
# Mở project trong Xcode
open ios/Runner.xcworkspace
```

Trong Xcode:
1. Chọn target "Runner"
2. Vào tab "Signing & Capabilities"
3. Chọn Team (Apple ID của bạn)
4. Xcode sẽ tự động tạo provisioning profile

#### 2. Kết nối iPhone và trust:
- Kết nối iPhone qua USB
- Trên iPhone: Settings → General → VPN & Device Management → Trust developer

#### 3. Chạy trên thiết bị:
```bash
# Xem danh sách devices
flutter devices

# Chạy trên thiết bị đã kết nối
flutter run -d <device-id>
```

Hoặc từ Xcode: Chọn device → Click Run (▶️)

---

## Cách 3: Test Build (Không cần Mac)

### Kiểm tra code analysis:
```bash
# Phân tích code Dart
flutter analyze

# Kiểm tra format
flutter format --dry-run lib/
```

### Kiểm tra iOS-specific code:
```bash
# Kiểm tra imports và platform-specific code
grep -r "Platform.isIOS" lib/
grep -r "import.*dart:io" lib/
```

---

## Cách 4: Sử dụng Cloud Testing Services

### Option 1: Codemagic (Free tier có sẵn)
1. Đăng ký tại https://codemagic.io
2. Connect GitHub repo
3. Setup iOS build configuration
4. Build và test trên cloud iOS simulators

### Option 2: GitHub Actions với macOS runner
Tạo file `.github/workflows/ios-test.yml`:
```yaml
name: iOS Test
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build ios --no-codesign
```

### Option 3: Appetize.io (Paid)
- Upload IPA file
- Test trên cloud iOS simulators
- Có free trial

---

## Kiểm Tra iOS-Specific Issues

### 1. Permissions trong Info.plist

Đã có trong `ios/Runner/Info.plist`:
- ✅ `NSLocationWhenInUseUsageDescription` - Location permission
- ✅ `NSLocationAlwaysUsageDescription` - Background location

**Cần thêm nếu thiếu:**
```xml
<!-- Cho camera (image_picker) -->
<key>NSCameraUsageDescription</key>
<string>Cần camera để chụp ảnh sản phẩm</string>

<!-- Cho photo library (image_picker) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Cần truy cập thư viện ảnh để chọn ảnh</string>

<!-- Cho notifications -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>location</string>
</array>
```

### 2. Kiểm tra Podfile

Tạo file `ios/Podfile` nếu chưa có:
```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

### 3. Kiểm tra Dependencies iOS-Compatible

Các packages đã dùng và iOS compatibility:
- ✅ `geolocator: ^11.0.0` - Cần location permissions
- ✅ `url_launcher: ^6.2.0` - Hoạt động tốt trên iOS
- ✅ `image_picker: ^1.1.2` - Cần camera/photo permissions
- ✅ `firebase_messaging: ^15.1.3` - Cần APNs setup
- ✅ `vietmap_flutter_gl: ^4.1.0` - Cần kiểm tra iOS support
- ✅ `supabase_flutter: ^2.9.0` - Hoạt động tốt trên iOS

---

## Checklist Test iOS

### Build & Compile
- [ ] `flutter pub get` chạy thành công
- [ ] `cd ios && pod install` chạy thành công
- [ ] `flutter build ios --no-codesign` build thành công
- [ ] Không có lỗi compile trong Xcode

### Permissions
- [ ] Location permission được request và grant
- [ ] Camera permission (nếu dùng image_picker)
- [ ] Photo library permission (nếu dùng image_picker)
- [ ] Notification permission (nếu dùng FCM)

### Functionality
- [ ] App launch thành công
- [ ] Đăng nhập/Đăng ký hoạt động
- [ ] Tạo đơn hàng thành công
- [ ] Xem đơn hàng hiển thị đúng
- [ ] Location services hoạt động
- [ ] Phone calls mở dialer (url_launcher)
- [ ] Image picker hoạt động (nếu có)
- [ ] Push notifications nhận được (nếu có)

### UI/UX
- [ ] UI hiển thị đúng trên các kích thước màn hình
- [ ] Safe area được xử lý đúng
- [ ] Keyboard không che input fields
- [ ] Navigation hoạt động mượt mà
- [ ] Loading states hiển thị đúng

### Performance
- [ ] App không crash
- [ ] Memory leaks không có
- [ ] Scroll performance tốt
- [ ] Network requests thành công

---

## Debug iOS Issues

### 1. Xem logs trong Xcode:
```bash
# Mở Xcode Console
# Window → Devices and Simulators → Chọn device → View Device Logs
```

### 2. Xem logs từ Flutter:
```bash
flutter logs
```

### 3. Common Issues:

#### Issue: "No such module 'Firebase'"
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

#### Issue: "Signing for Runner requires a development team"
- Mở `ios/Runner.xcworkspace` trong Xcode
- Chọn Runner target → Signing & Capabilities
- Chọn Team (Apple ID)

#### Issue: "Location permission not working"
- Kiểm tra `Info.plist` có `NSLocationWhenInUseUsageDescription`
- Test trên thiết bị thật (Simulator có thể không chính xác)

#### Issue: "Build failed with CocoaPods"
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

---

## Quick Test Commands

```bash
# 1. Kiểm tra setup
flutter doctor -v

# 2. Clean và rebuild
flutter clean
flutter pub get
cd ios && pod install && cd ..

# 3. Analyze code
flutter analyze

# 4. Build iOS (không cần Mac, chỉ check syntax)
flutter build ios --no-codesign --simulator

# 5. Test trên simulator (cần Mac)
flutter run -d ios

# 6. Xem devices có sẵn
flutter devices
```

---

## Lưu Ý Quan Trọng

1. **Không có Mac**: Bạn vẫn có thể:
   - Chạy `flutter analyze` để check code
   - Chạy `flutter build ios --no-codesign` để check build errors
   - Sử dụng cloud services (Codemagic, GitHub Actions)
   - Thuê Mac cloud (MacStadium, AWS Mac instances)

2. **Cần Mac để**:
   - Chạy iOS Simulator
   - Build và deploy lên App Store
   - Test trên thiết bị thật

3. **iOS Simulator Limitations**:
   - Location services có thể không chính xác
   - Phone calls không hoạt động thật
   - Push notifications cần cấu hình đặc biệt
   - Camera/Photo library cần setup ảnh mẫu

---

## Next Steps

1. Nếu có Mac: Setup và chạy trên Simulator
2. Nếu không có Mac: Setup GitHub Actions hoặc Codemagic
3. Test tất cả các tính năng trong checklist
4. Fix các issues nếu có
5. Deploy lên TestFlight để test trên thiết bị thật
