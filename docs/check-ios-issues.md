# Quick iOS Issues Check

## Commands để chạy trên Windows (không cần Mac)

### 1. Kiểm tra Code Analysis
```bash
cd choque
flutter analyze
```

### 2. Kiểm tra Build Errors (không cần Mac)
```bash
flutter build ios --no-codesign --simulator
```

### 3. Kiểm tra iOS-specific Code Issues

#### Tìm platform-specific code:
```bash
# Tìm code chỉ dành cho Android
grep -r "Platform.isAndroid" lib/

# Tìm code chỉ dành cho iOS  
grep -r "Platform.isIOS" lib/

# Tìm imports dart:io (platform-specific)
grep -r "import.*dart:io" lib/
```

#### Kiểm tra permissions trong Info.plist:
```bash
# Xem Info.plist
cat ios/Runner/Info.plist

# Kiểm tra các permissions cần thiết:
# - NSLocationWhenInUseUsageDescription ✅
# - NSLocationAlwaysUsageDescription ✅
# - NSCameraUsageDescription (cần thêm nếu dùng image_picker)
# - NSPhotoLibraryUsageDescription (cần thêm nếu dùng image_picker)
```

### 4. Kiểm tra Dependencies iOS-Compatible

Các packages cần kiểm tra:
- `geolocator` - Cần location permissions
- `url_launcher` - Cần LSApplicationQueriesSchemes trong Info.plist
- `image_picker` - Cần camera/photo permissions
- `firebase_messaging` - Cần APNs setup
- `vietmap_flutter_gl` - Cần kiểm tra iOS support

### 5. Kiểm tra Podfile

```bash
# Xem Podfile
cat ios/Podfile

# Nếu không có, cần tạo (Flutter sẽ tự tạo khi chạy pod install)
```

---

## Common iOS Issues và Cách Fix

### Issue 1: Missing Permissions
**Symptom**: App crash khi request permission

**Fix**: Thêm vào `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Cần camera để chụp ảnh sản phẩm</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Cần truy cập thư viện ảnh để chọn ảnh</string>
```

### Issue 2: url_launcher không hoạt động trên iOS
**Symptom**: Phone calls không mở dialer

**Fix**: Thêm vào `ios/Runner/Info.plist`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>tel</string>
    <string>sms</string>
    <string>mailto</string>
</array>
```

### Issue 3: Firebase không hoạt động
**Symptom**: Push notifications không nhận được

**Fix**: 
1. Kiểm tra `GoogleService-Info.plist` đã có trong `ios/Runner/`
2. Cấu hình APNs trong Firebase Console
3. Download và thêm APNs certificate

### Issue 4: Build failed với CocoaPods
**Symptom**: `pod install` fail

**Fix**:
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

## Checklist Trước Khi Test iOS

- [ ] `flutter analyze` không có errors
- [ ] `flutter build ios --no-codesign` build thành công
- [ ] Info.plist có đầy đủ permissions
- [ ] Podfile tồn tại và đúng format
- [ ] GoogleService-Info.plist đã có (nếu dùng Firebase)
- [ ] Không có platform-specific code gây lỗi
- [ ] Dependencies đều iOS-compatible
