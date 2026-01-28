# Báo cáo tiến độ Merchant App

## Tổng quan

Theo file `14-STITCH-SCREENS.md`, tất cả các màn merchant đã được đánh dấu là hoàn thành ✅. Tuy nhiên, sau khi redesign driver app theo Stitch, cần kiểm tra xem merchant app có cần cập nhật tương tự không.

---

## Các màn Merchant hiện có

### 1. ✅ Merchant Order Dashboard
**File:** `lib/screens/merchant/merchant_order_dashboard_screen.dart`

**Tính năng hiện tại:**
- Header với shop name và status
- Stats cards (Đơn chờ, Đơn đang xử lý, Doanh thu)
- Quick actions (Quản lý Profile Shop, Quản lý Menu & Giá)
- Tabs filter (Tất cả, Mới, Đang xử lý)
- Order list với MerchantOrderCard

**Cần kiểm tra:**
- [ ] Header có khớp với Stitch design không?
- [ ] Stats cards layout (ngang/dọc)?
- [ ] Quick actions có đúng style?
- [ ] Order cards có đầy đủ thông tin?

---

### 2. ✅ Merchant Order Management
**File:** `lib/screens/merchant/merchant_order_management_screen.dart`

**Tính năng hiện tại:**
- Order detail card
- Customer info
- Order items list
- Status info
- Action buttons (Accept/Reject/Update status)

**Cần kiểm tra:**
- [ ] Layout có khớp với Stitch?
- [ ] Timeline/status display?
- [ ] Action buttons style?

---

### 3. ✅ Merchant Price Management
**File:** `lib/screens/merchant/merchant_price_management_screen.dart`

**Tính năng hiện tại:**
- Search bar
- Category filter
- Menu items list
- Price edit modal
- Bulk update

**Cần kiểm tra:**
- [ ] Search bar style?
- [ ] Category chips?
- [ ] Item cards layout?
- [ ] Price edit modal design?

---

### 4. ✅ Merchant Profile Screen
**File:** `lib/screens/merchant/merchant_profile_screen.dart`

**Tính năng hiện tại:**
- Shop info form (name, phone, address, hours)
- Update functionality

**Cần kiểm tra:**
- [ ] Form layout?
- [ ] Input fields style?
- [ ] Save button?

---

### 5. ✅ New Order Request Popup
**File:** `lib/screens/merchant/new_order_request_popup.dart`

**Tính năng hiện tại:**
- Bottom sheet với order info
- Customer info
- Order items
- Total amount
- Accept/Reject buttons

**Cần kiểm tra:**
- [ ] Bottom sheet animation?
- [ ] Layout khớp với Stitch?
- [ ] Button styles?

---

### 6. ✅ Price Edit Modal
**File:** `lib/screens/merchant/price_edit_modal.dart`

**Tính năng hiện tại:**
- Price input form
- Save/Cancel buttons

**Cần kiểm tra:**
- [ ] Modal design?
- [ ] Form layout?

---

### 7. ✅ Confirm Flag Changes Sheet
**File:** `lib/screens/merchant/confirm_flag_changes_sheet.dart`

**Tính năng hiện tại:**
- Confirmation bottom sheet
- Flag changes display

**Cần kiểm tra:**
- [ ] Sheet design?

---

### 8. ✅ Product Picker Screen
**File:** `lib/screens/merchant/product_picker_screen.dart`

**Tính năng hiện tại:**
- Product selection
- Add to menu

**Cần kiểm tra:**
- [ ] Selection UI?

---

## So sánh với Driver App (đã redesign)

### Driver App đã được cập nhật:
1. ✅ Design System với colors mới (accentYellow, driver-specific colors)
2. ✅ Bottom Navigation Bar
3. ✅ Status Badge với pulse animation
4. ✅ Order cards với images
5. ✅ Bottom sheet với timer và earnings
6. ✅ Timeline stepper horizontal
7. ✅ Map background integration

### Merchant App cần kiểm tra:
1. ❓ Có cần bottom navigation không?
2. ❓ Header style có khớp với design system mới?
3. ❓ Stats cards có cần redesign không?
4. ❓ Order cards có cần thêm images không?
5. ❓ Popups/modals có đúng style không?

---

## Đề xuất hành động

### Ưu tiên cao:
1. **Kiểm tra Stitch designs cho merchant screens**
   - Lấy HTML/CSS từ Stitch cho các màn merchant
   - So sánh với code hiện tại
   - Xác định khác biệt

2. **Cập nhật Design System (nếu cần)**
   - Thêm merchant-specific colors (nếu có)
   - Đảm bảo consistency với driver app

3. **Redesign các màn chính:**
   - Merchant Order Dashboard
   - Merchant Order Management
   - New Order Request Popup

### Ưu tiên trung bình:
- Merchant Price Management
- Merchant Profile Screen
- Price Edit Modal

### Ưu tiên thấp:
- Confirm Flag Changes Sheet
- Product Picker Screen

---

## Checklist để bắt đầu

- [ ] Lấy Stitch project ID cho merchant screens
- [ ] List tất cả merchant screens trong Stitch
- [ ] Fetch HTML/CSS cho từng màn
- [ ] So sánh với Flutter code hiện tại
- [ ] Tạo plan chi tiết cho từng màn
- [ ] Bắt đầu redesign theo thứ tự ưu tiên

---

## Ghi chú

- Merchant app có thể không cần bottom navigation như driver (vì merchant thường làm việc trên desktop/tablet)
- Cần kiểm tra xem có merchant-specific design tokens không
- So sánh với customer app để đảm bảo consistency
