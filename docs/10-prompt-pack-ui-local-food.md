# Prompt Pack Thiết kế UI Đồng nhất (Local Food App)

> Dùng file này làm “nguồn sự thật” để Stitch/AI IDE/Agent code ra UI đồng nhất cho toàn bộ ứng dụng.

---

## 0) Bối cảnh nghiệp vụ (tóm tắt)

**Vai trò (4 tầng):**
1. **Admin tổng (chủ app)**: quản trị hệ thống, up menu & hình ảnh cho cửa hàng, duyệt/tạm khoá cửa hàng, cấu hình modes.
2. **Chủ cửa hàng (admin cửa hàng)**: vận hành đơn + **chỉ được chỉnh giá**.
3. **Tài xế**: nhận đơn, lấy hàng, giao, cập nhật trạng thái.
4. **Người dùng**: khám phá cửa hàng, đặt món, thanh toán, theo dõi đơn (timeline đơn giản).

**Feature flags / Modes (bật/tắt):**
- Auth: **Guest vs OTP**
- Address: **Manual Address (địa chỉ quê) vs Google Maps**
- Pricing: **Fixed fee vs GPS fee**
- Tracking: **Simple tracking** (timeline trạng thái)

---

## 1) Design System bắt buộc (Palette + Contrast Rules)

### 1.1 Palette tokens
- Primary / Green: `#1E7F43`
- Primary / Green Dark: `#145A32`
- Primary / Green Light: `#6FCF97`
- Accent / Yellow: `#F2C94C`
- Neutral / White: `#FFFFFF`
- Neutral / Text Dark: `#1B1B1B`
- Neutral / Grey: `#E0E0E0`

### 1.2 Quy tắc tương phản (bắt buộc)
- **Chữ trắng chỉ dùng trên**: `#1E7F43`, `#145A32`
- **Không dùng chữ trắng trên**: `#6FCF97`, `#F2C94C` → dùng chữ `#1B1B1B`

---

## 2) PROMPT GỐC (dán một lần – áp cho mọi màn)

```text
Bạn là Senior Product Designer chuyên thiết kế mobile app. Hãy thiết kế UI theo phong cách hiện đại, rõ ràng, dễ dùng, ưu tiên khả năng triển khai thực tế.

Sản phẩm: Local Food / Local Service App (đặt món/đặt dịch vụ địa phương + giao nhận).
Nền tảng: Mobile (iOS/Android), bố cục ưu tiên Flutter-friendly.

Mục tiêu: Tạo bộ UI đồng nhất giữa 4 vai trò: Người dùng, Tài xế, Chủ cửa hàng, Admin tổng.

PALETTE (bắt buộc dùng đúng token):
- Primary Green: #1E7F43
- Primary Green Dark: #145A32
- Primary Green Light: #6FCF97
- Accent Yellow: #F2C94C
- White: #FFFFFF
- Text Dark: #1B1B1B
- Grey: #E0E0E0

QUY TẮC TƯƠNG PHẢN (bắt buộc):
- Chữ trắng chỉ dùng trên: Primary Green (#1E7F43) và Green Dark (#145A32)
- Tránh chữ trắng trên: Green Light (#6FCF97) và Yellow (#F2C94C); các nền này dùng chữ Text Dark (#1B1B1B)

STYLE SYSTEM:
- Grid 8pt, khoảng cách thoáng, ưu tiên đọc nhanh
- Corner radius 12–16, card nhẹ, shadow rất tinh tế
- Typography: 1 font sans (Inter/SF/Roboto), hệ cỡ: 12/14/16/20/24
- Icon line đơn giản, đồng bộ nét
- Button states đầy đủ: default/pressed/disabled/loading
- Form input có label + helper + error, rõ ràng
- Thẻ trạng thái (status chip) dùng Green Light / Grey / Yellow (chữ Text Dark)
- Thiết kế ưu tiên 1 tay, CTA đặt dưới

COMPONENTS (cần có trong mọi màn):
- App bar, search, tabs, filter chips
- Card item, list row, empty state, skeleton loading
- Bottom sheet xác nhận, toast/snackbar
- Badge số lượng, stepper số lượng, price display chuẩn

NGHIỆP VỤ BẬT/TẮT (feature flags):
- Auth: Guest vs OTP
- Address: Manual (địa chỉ quê) vs Google Maps
- Pricing: Fixed fee vs GPS fee
- Tracking: simple tracking (timeline trạng thái)

Output mong muốn:
- Mỗi màn: mô tả layout + hierarchy + component list + states + ghi chú tương tác
- Giữ đồng nhất design language trên toàn bộ flow
```

---

## 3) PROMPT tạo UI KIT + DESIGN TOKENS

```text
Dựa trên PROMPT GỐC, hãy tạo “UI Kit” cho app gồm:
1) Color tokens và quy tắc dùng
2) Typography scale (H1/H2/Body/Caption)
3) Spacing & radius & elevation
4) Components: Primary/Secondary/Tertiary button + icon button + input + dropdown + OTP input + search bar + tabs + chips + cards + list rows + empty state + dialog + bottom sheet + toast + badges + stepper + price tag.
5) Mẫu trạng thái: loading/empty/error/success
6) Ví dụ 2 theme: Light (bắt buộc) và Dark (tuỳ chọn, nhưng vẫn giữ tinh thần palette)
Xuất ra theo dạng guideline rõ ràng để dùng cho mọi màn hình.
```

---

## 4) TEMPLATE “Screen Spec” dạng checklist (chuẩn Stitch)

### A. Thông tin màn
- [ ] Tên màn: …
- [ ] Vai trò: User / Driver / Shop Admin / Admin tổng
- [ ] Mục tiêu chính của màn: …
- [ ] Feature flags ảnh hưởng:
  - [ ] Guest vs OTP
  - [ ] Manual Address vs Google Maps
  - [ ] Fixed fee vs GPS fee
  - [ ] Simple tracking on/off

### B. App Bar
- [ ] Title: …
- [ ] Leading: Back / Close / Menu / None
- [ ] Actions (tối đa 2): Search / Filter / Help / More / …
- [ ] Behavior: scroll collapse? (mặc định: không)

### C. Body theo “Card Sections”
Quy tắc chung:
- [ ] Nền: `#FFFFFF`
- [ ] Text: `#1B1B1B`
- [ ] Card: radius 12–16, viền `#E0E0E0` hoặc shadow rất nhẹ
- [ ] Spacing theo grid 8pt

Mỗi section:
- [ ] Section #…: Tên section
  - [ ] Kiểu: Card / List / Form / Summary
  - [ ] Nội dung: …
  - [ ] Component: …
  - [ ] Actions: …
  - [ ] Validation: …
  - [ ] Empty state riêng section (nếu có)

### D. Sticky Bottom CTA (nếu có)
- [ ] Hiển thị khi: …
- [ ] CTA label: …
- [ ] CTA style:
  - Primary: nền `#1E7F43`, chữ trắng
  - Pressed: `#145A32`, chữ trắng
  - Disabled: nền `#E0E0E0`, chữ `#1B1B1B`
- [ ] Loading: spinner + disable tap

### E. States (bắt buộc)
- [ ] Loading: skeleton cards/list + CTA disabled
- [ ] Empty: icon + headline + mô tả ngắn + CTA gợi ý
- [ ] Error: message rõ + “Thử lại” (+ tuỳ chọn “Liên hệ”)

### F. Quy tắc màu
- [ ] Chữ trắng chỉ dùng trên `#1E7F43` và `#145A32`
- [ ] `#6FCF97` và `#F2C94C` dùng chữ `#1B1B1B`
- [ ] Accent Yellow chỉ nhấn nhỏ (badge/chip/icon), tránh làm nền lớn

### G. Tương tác
- [ ] Tap chính: …
- [ ] Bottom sheet confirm (nếu có): …
- [ ] Toast/snackbar: …

---

## 5) PROMPT “Stitch Screen” (khung tạo 1 màn)

```text
Thiết kế UI mobile cho màn: <TÊN MÀN>.
Vai trò: <ROLE>. Mục tiêu: <MỤC TIÊU>.

BẮT BUỘC: dùng đúng palette token:
- Primary Green #1E7F43, Green Dark #145A32, Green Light #6FCF97, Accent Yellow #F2C94C
- White #FFFFFF, Text Dark #1B1B1B, Grey #E0E0E0
QUY TẮC: chữ trắng chỉ trên #1E7F43 và #145A32; không chữ trắng trên #6FCF97 và #F2C94C.

LAYOUT TEMPLATE:
- App bar: title + actions (nếu có)
- Body: chia thành card sections, spacing theo grid 8pt, radius 12–16
- Sticky bottom CTA (nếu có)
- States: loading/empty/error

SECTION LIST (ghi rõ từng section):
1) ...
2) ...
3) ...

CTA (nếu có):
- Label: ...
- Conditions show/hide: ...
- States: default/pressed/disabled/loading

FEATURE FLAGS ảnh hưởng (nếu có): <liệt kê và mô tả biến thể A/B>

Output: mô tả rõ hierarchy + component list + interaction + states.
```

---

## 6) PROMPT Feature Flags / App Modes (Admin tổng)

```text
Thiết kế màn “Feature Flags / App Modes” cho Admin tổng:
- 4 toggle: Guest vs OTP, Manual Address vs Google Maps, Fixed fee vs GPS fee, Simple tracking on/off
- Mỗi toggle có mô tả ngắn, trạng thái hiện tại, và cảnh báo ảnh hưởng
- Có nút “Apply changes” và cơ chế confirm bottom sheet
- Có log nhỏ “Last updated by / time”
UI rõ ràng, cảm giác hệ thống, không rối.
```

---

## 7) PROMPT cho Người dùng (Customer) – Full Flow

### 7.1 Onboarding + Login (Guest/OTP)
```text
Thiết kế flow Onboarding tối giản 2–3 màn:
- Màn chào: value proposition + CTA “Bắt đầu”
- Màn chọn đăng nhập:
  - Nếu OTP mode ON: login bằng số điện thoại + OTP
  - Nếu Guest mode ON: “Tiếp tục với tư cách khách” + gợi ý lợi ích khi đăng nhập
- Input/OTP states: focus/error/loading/resend
CTA rõ ràng, không dài dòng.
```

### 7.2 Chọn địa chỉ (Manual vs Google)
```text
Thiết kế màn “Chọn địa chỉ giao hàng” có 2 biến thể theo mode:
A) Manual Address: dropdown Tỉnh/Huyện/Xã + ô nhập chi tiết + lưu địa chỉ yêu thích
B) Google Maps: search địa điểm + map preview + pin + xác nhận
Hai biến thể phải cùng ngôn ngữ thiết kế (cùng card/input style).
```

### 7.3 Home + Khám phá cửa hàng
```text
Thiết kế màn Home:
- App bar: vị trí hiện tại + search
- Section: cửa hàng gần bạn, danh mục, ưu đãi (nếu có)
- List card cửa hàng: ảnh, tên, rating, thời gian giao, khoảng cách (nếu có), tag (mở/đóng)
- Filter chips: “Gần nhất”, “Bán chạy”, “Giá tốt”
Có empty state khi không có cửa hàng.
```

### 7.4 Store Detail + Menu
```text
Thiết kế màn Store Detail:
- Header: ảnh bìa + tên + rating + giờ mở + nút liên hệ
- Tabs: “Menu”, “Đánh giá”, “Thông tin”
- Menu list theo category; item card: ảnh, tên, mô tả, giá, nút “Thêm”
- Khi thêm vào giỏ: mini cart bar xuất hiện dưới cùng (tổng + CTA)
States: loading skeleton, hết hàng, cửa hàng đóng.
```

### 7.5 Cart + Checkout (Fixed fee vs GPS fee)
```text
Thiết kế màn Cart/Checkout có 2 biến thể tính phí:
A) Fixed fee: hiển thị phí cố định, giải thích ngắn
B) GPS fee: hiển thị ước tính theo khoảng cách (UI đơn giản)
Các phần: món + ghi chú + chọn địa chỉ + (tuỳ) thanh toán + tổng tiền.
CTA “Đặt đơn” sticky bottom.
```

### 7.6 Tracking đơn giản (Simple Tracking)
```text
Thiết kế màn “Theo dõi đơn” dạng timeline đơn giản:
Đã đặt → Cửa hàng xác nhận → Tài xế nhận → Đang giao → Hoàn tất
- Icon + timestamp + mô tả ngắn
- Card info: mã đơn, cửa hàng, địa chỉ, tổng tiền
- Nút “Liên hệ” (tuỳ) và “Báo sự cố”
Không dùng map phức tạp.
```

---

## 8) PROMPT cho Tài xế (Driver)

### 8.1 Driver Home + Nhận đơn
```text
Thiết kế Driver Home:
- Toggle Online/Offline nổi bật
- Danh sách đơn gần đây + khu vực hoạt động
- Khi có đơn mới: bottom sheet nhận đơn với thông tin pickup/dropoff, phí giao
Ưu tiên thao tác nhanh, một tay.
```

### 8.2 Driver Order Detail + Update status
```text
Thiết kế màn Driver Order Detail:
- Pickup info + Dropoff info
- Nếu Google Address mode ON: có nút mở bản đồ (CTA)
- Nút cập nhật trạng thái: “Đã đến điểm lấy”, “Đã lấy hàng”, “Bắt đầu giao”, “Đã giao”
- Nút gọi/nhắn (tuỳ)
States: disable khi chưa đúng bước.
```

---

## 9) PROMPT cho Chủ cửa hàng (Shop Admin)

### 9.1 Dashboard + Đơn đến
```text
Thiết kế màn Shop Dashboard:
- Summary cards: đơn mới, đang làm, hoàn tất hôm nay
- Tabs: “Mới”, “Đang chuẩn bị”, “Hoàn tất/Huỷ”
- Action nhanh đơn mới: “Xác nhận” / “Từ chối” + lý do
UI gọn, dễ scan.
```

### 9.2 Quản lý giá (chỉ sửa giá)
```text
Thiết kế màn “Quản lý giá”:
- List món: ảnh nhỏ + tên + giá hiện tại
- Chỉ cho phép sửa giá: inline edit hoặc modal
- Hiển thị “giá đang áp dụng”
- Nút lưu, có loading/success
Không có thêm/xóa món hay upload ảnh.
```

---

## 10) PROMPT cho Admin tổng (App Owner)

### 10.1 Quản lý cửa hàng đối tác
```text
Thiết kế màn Admin quản lý cửa hàng:
- List cửa hàng + trạng thái pending/active/paused
- Search + filter
- Detail: thông tin, tài khoản chủ quán, cấu hình mode, lịch sử thay đổi
- Action: duyệt/tạm khoá/khôi phục
Tone system admin, vẫn cùng design language.
```

### 10.2 Upload menu + hình ảnh (Admin làm)
```text
Thiết kế màn Admin “Quản lý menu & hình ảnh”:
- Chọn cửa hàng
- CRUD menu: category → item (tên, mô tả, giá, ảnh)
- Upload ảnh có progress + preview
- Preview item card giống UI người dùng
Có validation rõ (thiếu tên/giá/ảnh).
```

---

## 11) PROMPT “Screen Template” (xuất template + ví dụ 1 màn)

```text
Tạo một template cho mọi màn hình trong app:
- App bar tiêu đề + hành động (nếu có)
- Body theo card sections
- Sticky bottom CTA (nếu có hành động chính)
- Trạng thái: loading/empty/error
- Quy tắc dùng màu theo PROMPT GỐC
Xuất template dưới dạng checklist + ví dụ 1 màn bất kỳ áp dụng template.
```

---

## 12) Gợi ý dùng trong AI IDE (không bắt buộc)

- Lưu file này trong repo: `design/prompt-pack.md`
- Khi chat với AI IDE: “Hãy tuân theo `design/prompt-pack.md` và implement màn X”
- Nếu có ảnh màn: đính kèm thêm PNG để đạt gần 1:1

---

**Kết thúc.**
