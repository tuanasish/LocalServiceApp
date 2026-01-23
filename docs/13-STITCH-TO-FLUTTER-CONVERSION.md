# Chuyển đổi Stitch Design sang Flutter Code

## ✅ Kết quả

**Có thể chuyển đổi chính xác** các design từ Stitch sang Flutter code!

## 📋 Quy trình chuyển đổi

### 1. Lấy code từ Stitch
- Sử dụng MCP Stitch tools để lấy HTML/CSS code
- Phân tích cấu trúc layout, colors, typography

### 2. Mapping Design → Flutter

| Stitch (HTML/CSS) | Flutter Widget |
|-------------------|----------------|
| `div` với `flex` | `Row` / `Column` |
| `grid` | `GridView` |
| `rounded-2xl` | `BorderRadius.circular(24)` |
| `bg-primary` | `Color(0xFF1E7F43)` |
| `font-inter` | `GoogleFonts.inter()` |
| `shadow-soft` | `BoxShadow` với opacity |
| `fixed bottom-0` | `bottomNavigationBar` |

### 3. Colors từ Design

```dart
// Primary color từ Stitch
const Color primary = Color(0xFF1E7F43); // #1E7F43

// Background colors
const Color backgroundLight = Color(0xFFF8FAFC); // #f8fafc
const Color surfaceLight = Color(0xFFFFFFFF); // #ffffff

// Text colors
const Color textPrimary = Color(0xFF0F172A);
const Color textSecondary = Color(0xFF64748B);
```

### 4. Typography

```dart
// Sử dụng Google Fonts Inter
GoogleFonts.inter(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white,
)
```

### 5. Layout Components

- **Header với rounded bottom**: `Container` với `BorderRadius.only`
- **Search bar**: `TextField` trong `Container` với shadow
- **Category grid**: `GridView.builder` với 4 columns
- **Horizontal scroll**: `ListView` với `scrollDirection: Axis.horizontal`
- **Cards**: `Container` với `BoxDecoration` và shadow
- **Bottom nav**: `bottomNavigationBar` property

## 📁 File đã tạo

### `lib/screens/home/user_home_screen.dart`

Đã chuyển đổi screen **"User Home Screen"** với:

✅ Header với địa chỉ giao hàng  
✅ Search bar với filter icon  
✅ Category grid (8 categories)  
✅ Featured Merchants (horizontal scroll)  
✅ Popular Near You (vertical list)  
✅ Bottom navigation bar  

## 🎨 Design System

### Colors
- Primary: `#1E7F43`
- Background Light: `#F8FAFC`
- Surface: `#FFFFFF`
- Text Primary: `#0F172A`
- Text Secondary: `#64748B`

### Typography
- Font Family: Inter (via `google_fonts` package)
- Font Weights: 400, 500, 600, 700

### Border Radius
- Small: 12px (rounded-xl)
- Medium: 16px (rounded-2xl)
- Large: 24px (rounded-3xl)
- Full: 9999px (rounded-full)

### Shadows
- Soft shadow: `BoxShadow` với `opacity: 0.05`, `blurRadius: 20`

## 📦 Dependencies cần thiết

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0  # Cho Inter font
```

## 🔄 Các screens khác có thể chuyển đổi

Từ project Chợ Quê, có thể chuyển đổi:

1. ✅ **User Home Screen** - Đã làm
2. ⏳ Food Home - Discover
3. ⏳ Store Detail & Menu
4. ⏳ Checkout screens
5. ⏳ Driver Dashboard
6. ⏳ Admin screens
7. ⏳ Login/Onboarding
8. ⏳ Order tracking

## 💡 Tips chuyển đổi

1. **Phân tích HTML structure trước**: Xem layout hierarchy
2. **Map colors chính xác**: Dùng Color picker để lấy hex codes
3. **Typography matching**: Đảm bảo font size, weight giống design
4. **Spacing**: Chuyển padding/margin từ Tailwind sang Flutter
5. **Icons**: Material Icons có thể thay thế Material Symbols
6. **Images**: Dùng `Image.network` hoặc `CachedNetworkImage`

## ⚠️ Lưu ý

- **Icons**: Material Symbols trong HTML → Material Icons trong Flutter (có thể khác một chút)
- **Images**: Cần thay placeholder URLs bằng real images
- **Interactions**: Cần thêm `onTap` handlers và state management
- **Responsive**: Cần test trên nhiều screen sizes

## 🚀 Next Steps

1. Thêm `google_fonts` vào `pubspec.yaml`
2. Chạy `flutter pub get`
3. Test screen trong app
4. Chuyển đổi các screens khác
5. Tạo reusable widgets cho common components
