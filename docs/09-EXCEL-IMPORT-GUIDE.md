# CHỢ QUÊ - EXCEL TEMPLATE HƯỚNG DẪN

## 📦 TEMPLATE IMPORT MENU (Products)

### File: `menu_template.csv`

```csv
name,description,base_price,category,status
Phở bò,Phở bò tái nạm gầu,40000,Phở/Bún,active
Phở gà,Phở gà ta,40000,Phở/Bún,active
Bún chả,Bún chả Hà Nội,35000,Phở/Bún,active
Bún riêu,Bún riêu cua đồng,35000,Phở/Bún,active
Cơm sườn,Cơm sườn nướng + canh + rau,35000,Cơm,active
Cơm gà,Cơm gà rán + canh + rau,35000,Cơm,active
Cơm rang,Cơm rang dưa bò,30000,Cơm,active
Trà đá,Trà đá,5000,Đồ uống,active
Nước mía,Nước mía ép tươi,15000,Đồ uống,active
Cà phê đen,Cà phê đen đá,15000,Đồ uống,active
Cà phê sữa,Cà phê sữa đá,20000,Đồ uống,active
```

---

## 📋 HƯỚNG DẪN SỬ DỤNG

### Bước 1: Tải template
- Copy bảng trên vào Excel/Google Sheets
- Hoặc tải file CSV mẫu

### Bước 2: Điền dữ liệu
| Column | Bắt buộc | Mô tả | Ví dụ |
|--------|----------|-------|-------|
| `name` | ✅ | Tên món | Phở bò |
| `description` | ❌ | Mô tả ngắn | Phở bò tái nạm |
| `base_price` | ✅ | Giá (VND, số nguyên) | 40000 |
| `category` | ❌ | Danh mục | Phở/Bún, Cơm, Đồ uống |
| `status` | ❌ | Trạng thái | active / inactive |

### Bước 3: Lưu file
- **Excel**: Save As → CSV UTF-8 (Comma delimited)
- **Google Sheets**: File → Download → CSV

### Bước 4: Import vào Supabase
1. Mở Supabase Dashboard
2. Vào **Table Editor** → Chọn bảng `products`
3. Click **Insert** → **Import data from CSV**
4. Chọn file CSV
5. Map columns → Import

---

## 🏪 TEMPLATE IMPORT SHOPS

### File: `shops_template.csv`

```csv
market_id,name,address,phone,status
huyen_demo,Quán Cơm Bà Năm,123 Đường chính TT Huyện,0901234567,active
huyen_demo,Quán Phở Ông Bảy,45 Đường chợ TT Huyện,0901234568,active
huyen_demo,Quán Bún Chị Hoa,67 Ngõ 2 TT Huyện,0901234569,active
```

---

## 📍 TEMPLATE IMPORT PRESET LOCATIONS

### File: `locations_template.csv`

```csv
market_id,label,address,lat,lng,location_type,sort_order
huyen_demo,Chợ Huyện,Chợ trung tâm huyện,21.0285,105.8542,landmark,1
huyen_demo,UBND Huyện,Trụ sở UBND huyện,21.0290,105.8550,landmark,2
huyen_demo,Bệnh viện Huyện,Bệnh viện đa khoa,21.0275,105.8530,landmark,3
huyen_demo,Quán Cơm Bà Năm,123 Đường chính,21.0288,105.8545,restaurant,30
```

### Location Types:
- `landmark` - Địa điểm công cộng (chợ, UB, bệnh viện...)
- `restaurant` - Quán ăn
- `general` - Khác

---

## 🎫 TEMPLATE IMPORT PROMOTIONS

### File: `promotions_template.csv`

```csv
market_id,code,name,description,promo_type,discount_type,discount_value,min_order_value,max_total_uses,max_uses_per_user,status
huyen_demo,,Freeship đơn đầu,Miễn phí ship đơn đầu tiên,first_order,freeship,50000,0,,1,active
huyen_demo,GIAM10K,Giảm 10K,Nhập mã để giảm 10.000đ,voucher,fixed,10000,30000,100,1,active
huyen_demo,SALE20,Giảm 20%,Giảm 20% tối đa 30K,voucher,percent,20,50000,50,1,active
```

### Promo Types:
- `first_order` - Tự động apply cho đơn đầu (code để trống)
- `voucher` - Nhập mã để dùng
- `all_orders` - Apply cho tất cả đơn

### Discount Types:
- `freeship` - Miễn phí ship (discount_value = max freeship)
- `fixed` - Giảm cố định (VD: 10000 = giảm 10K)
- `percent` - Giảm % (VD: 20 = giảm 20%)

---

## 💲 TEMPLATE IMPORT FIXED PRICING

### File: `pricing_template.csv`

```csv
market_id,service_type,zone_name,price
huyen_demo,food,Nội thị trấn,10000
huyen_demo,food,Liên xã gần,15000
huyen_demo,food,Liên xã xa,25000
```

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **UTF-8 Encoding**: File phải lưu dạng UTF-8 để hiển thị tiếng Việt
2. **Không có header trùng**: Column names phải khớp chính xác
3. **Giá là số nguyên**: 40000 ✅ | 40.000 ❌ | 40,000 ❌
4. **market_id phải tồn tại**: Dùng `huyen_demo` cho test
5. **UUID tự sinh**: Không cần điền cột `id`

---

## 🔄 SAU KHI IMPORT

### Assign products cho shops:
```sql
-- Gán tất cả sản phẩm cho 1 shop
INSERT INTO public.shop_products (shop_id, product_id)
SELECT 
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',  -- Shop ID
  id 
FROM public.products 
WHERE status = 'active';
```

### Kiểm tra data:
```sql
-- Xem menu của shop
SELECT * FROM public.v_shop_menu 
WHERE shop_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

-- Xem promotions active
SELECT * FROM public.promotions WHERE status = 'active';
```
