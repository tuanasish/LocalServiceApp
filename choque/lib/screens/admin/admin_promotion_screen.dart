import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/admin_promotion_provider.dart';
import '../../ui/design_system.dart';

class AdminPromotionScreen extends ConsumerStatefulWidget {
  const AdminPromotionScreen({super.key});

  @override
  ConsumerState<AdminPromotionScreen> createState() => _AdminPromotionScreenState();
}

class _AdminPromotionScreenState extends ConsumerState<AdminPromotionScreen> {
  String _filter = 'all'; // all, active, paused, expired

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(adminPromotionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý Khuyến mãi'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePromotionDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Đang chạy', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Tạm dừng', 'paused'),
                const SizedBox(width: 8),
                _buildFilterChip('Hết hạn', 'expired'),
              ],
            ),
          ),
          // Promotions list
          Expanded(
            child: promotionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Lỗi: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(adminPromotionsProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (promotions) {
                final filtered = _filterPromotions(promotions);
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có khuyến mãi nào',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showCreatePromotionDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo khuyến mãi'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminPromotionsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildPromotionCard(filtered[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePromotionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tạo mới'),
      ),
    );
  }

  List<Promotion> _filterPromotions(List<Promotion> promotions) {
    switch (_filter) {
      case 'active':
        return promotions.where((p) => p.isActive && !p.isExpired).toList();
      case 'paused':
        return promotions.where((p) => p.isPaused).toList();
      case 'expired':
        return promotions.where((p) => p.isExpired || p.isUsageLimitReached).toList();
      default:
        return promotions;
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildPromotionCard(Promotion promo) {
    final statusColor = promo.isExpired || promo.isUsageLimitReached
        ? AppColors.textSecondary
        : promo.isActive
            ? AppColors.success
            : AppColors.warning;

    final statusText = promo.isExpired
        ? 'Hết hạn'
        : promo.isUsageLimitReached
            ? 'Hết lượt'
            : promo.isActive
                ? 'Đang chạy'
                : 'Tạm dừng';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPromotionDetailsDialog(promo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPromoTypeColor(promo.promoType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      promo.promoTypeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getPromoTypeColor(promo.promoType),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, promo),
                    itemBuilder: (context) => [
                      if (promo.isActive && !promo.isExpired)
                        const PopupMenuItem(value: 'pause', child: Text('Tạm dừng')),
                      if (promo.isPaused && !promo.isExpired)
                        const PopupMenuItem(value: 'resume', child: Text('Tiếp tục')),
                      const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                      const PopupMenuItem(value: 'stats', child: Text('Xem thống kê')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Name & Code
              Text(
                promo.name,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (promo.code != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    promo.code!,
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Discount
              Text(
                promo.discountDisplay,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Usage & Validity
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    promo.hasUsageLimit
                        ? '${promo.currentUses}/${promo.maxTotalUses} lượt'
                        : '${promo.currentUses} lượt',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    promo.validTo != null
                        ? 'Đến ${DateFormat('dd/MM/yyyy').format(promo.validTo!)}'
                        : 'Không giới hạn',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPromoTypeColor(String promoType) {
    switch (promoType) {
      case 'first_order':
        return const Color(0xFF8B5CF6);
      case 'voucher':
        return AppColors.primary;
      case 'all_orders':
        return const Color(0xFF10B981);
      default:
        return AppColors.textSecondary;
    }
  }

  void _handleMenuAction(String action, Promotion promo) async {
    switch (action) {
      case 'pause':
        await _toggleStatus(promo, 'paused');
        break;
      case 'resume':
        await _toggleStatus(promo, 'active');
        break;
      case 'edit':
        _showEditPromotionDialog(promo);
        break;
      case 'stats':
        _showStatsDialog(promo);
        break;
    }
  }

  Future<void> _toggleStatus(Promotion promo, String status) async {
    try {
      await adminTogglePromotionStatus(promoId: promo.id, status: status);
      ref.invalidate(adminPromotionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'paused' ? 'Đã tạm dừng khuyến mãi' : 'Đã tiếp tục khuyến mãi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showPromotionDetailsDialog(Promotion promo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promo.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (promo.code != null) _buildDetailRow('Mã code', promo.code!),
              _buildDetailRow('Loại', promo.promoTypeLabel),
              _buildDetailRow('Giảm giá', promo.discountDisplay),
              _buildDetailRow('Đơn tối thiểu', '${NumberFormat('#,###').format(promo.minOrderValue)}đ'),
              _buildDetailRow('Đã dùng', '${promo.currentUses}/${promo.maxTotalUses ?? '∞'} lượt'),
              _buildDetailRow('Giới hạn/user', '${promo.maxUsesPerUser} lượt'),
              _buildDetailRow('Bắt đầu', DateFormat('dd/MM/yyyy HH:mm').format(promo.validFrom)),
              _buildDetailRow('Kết thúc', promo.validTo != null 
                  ? DateFormat('dd/MM/yyyy HH:mm').format(promo.validTo!) 
                  : 'Không giới hạn'),
              if (promo.description != null) ...[
                const SizedBox(height: 8),
                Text(promo.description!, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditPromotionDialog(promo);
            },
            child: const Text('Chỉnh sửa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showStatsDialog(Promotion promo) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final statsAsync = ref.watch(promotionStatsProvider(promo.id));
          
          return AlertDialog(
            title: Text('Thống kê: ${promo.name}'),
            content: statsAsync.when(
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Lỗi: $e'),
              data: (stats) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatRow('Tổng lượt dùng', '${stats.totalUses}'),
                  _buildStatRow('Tổng giảm giá', '${NumberFormat('#,###').format(stats.totalDiscountApplied)}đ'),
                  _buildStatRow('Số user dùng', '${stats.uniqueUsers}'),
                  _buildStatRow('Doanh thu ảnh hưởng', '${NumberFormat('#,###').format(stats.revenueImpact)}đ'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  void _showCreatePromotionDialog() {
    _showPromotionFormDialog(null);
  }

  void _showEditPromotionDialog(Promotion promo) {
    _showPromotionFormDialog(promo);
  }

  void _showPromotionFormDialog(Promotion? promo) {
    final isEdit = promo != null;
    final nameController = TextEditingController(text: promo?.name);
    final codeController = TextEditingController(text: promo?.code);
    final descController = TextEditingController(text: promo?.description);
    final discountValueController = TextEditingController(text: promo?.discountValue.toString() ?? '');
    final maxDiscountController = TextEditingController(text: promo?.maxDiscount?.toString() ?? '');
    final minOrderController = TextEditingController(text: promo?.minOrderValue.toString() ?? '0');
    final maxTotalUsesController = TextEditingController(text: promo?.maxTotalUses?.toString() ?? '');
    final maxUsesPerUserController = TextEditingController(text: promo?.maxUsesPerUser.toString() ?? '1');

    String promoType = promo?.promoType ?? 'voucher';
    String discountType = promo?.discountType ?? 'fixed';
    DateTime? validTo = promo?.validTo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Chỉnh sửa khuyến mãi' : 'Tạo khuyến mãi mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên khuyến mãi *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã code',
                    hintText: 'VD: GIAM10K (để trống = tự động apply)',
                  ),
                  enabled: !isEdit, // Can't change code after creation
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Promo Type
                if (!isEdit) ...[
                  const Text('Loại khuyến mãi', style: TextStyle(fontSize: 12)),
                  DropdownButton<String>(
                    value: promoType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'voucher', child: Text('Mã voucher')),
                      DropdownMenuItem(value: 'first_order', child: Text('Đơn đầu tiên')),
                      DropdownMenuItem(value: 'all_orders', child: Text('Tất cả đơn')),
                    ],
                    onChanged: (v) => setDialogState(() => promoType = v!),
                  ),
                  const SizedBox(height: 12),

                  // Discount Type
                  const Text('Loại giảm giá', style: TextStyle(fontSize: 12)),
                  DropdownButton<String>(
                    value: discountType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'fixed', child: Text('Giảm cố định (VNĐ)')),
                      DropdownMenuItem(value: 'percent', child: Text('Giảm %')),
                      DropdownMenuItem(value: 'freeship', child: Text('Miễn phí ship')),
                    ],
                    onChanged: (v) => setDialogState(() => discountType = v!),
                  ),
                  const SizedBox(height: 12),
                ],

                // Discount Value
                TextField(
                  controller: discountValueController,
                  decoration: InputDecoration(
                    labelText: discountType == 'percent' ? 'Phần trăm giảm (%) *' : 'Số tiền giảm (VNĐ) *',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                if (discountType == 'percent')
                  TextField(
                    controller: maxDiscountController,
                    decoration: const InputDecoration(labelText: 'Giảm tối đa (VNĐ)'),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 12),

                TextField(
                  controller: minOrderController,
                  decoration: const InputDecoration(labelText: 'Đơn tối thiểu (VNĐ)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxTotalUsesController,
                        decoration: const InputDecoration(labelText: 'Tổng lượt dùng'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxUsesPerUserController,
                        decoration: const InputDecoration(labelText: 'Lượt/user'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Valid To
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày hết hạn'),
                  subtitle: Text(
                    validTo != null 
                        ? DateFormat('dd/MM/yyyy').format(validTo!) 
                        : 'Không giới hạn',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: validTo ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => validTo = date);
                          }
                        },
                      ),
                      if (validTo != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setDialogState(() => validTo = null),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final discountValue = int.tryParse(discountValueController.text) ?? 0;

                if (name.isEmpty || discountValue <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Vui lòng nhập tên và giá trị giảm'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  if (isEdit) {
                    await adminUpdatePromotion(
                      promoId: promo.id,
                      name: name,
                      description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                      discountValue: discountValue,
                      maxDiscount: int.tryParse(maxDiscountController.text),
                      minOrderValue: int.tryParse(minOrderController.text) ?? 0,
                      maxTotalUses: int.tryParse(maxTotalUsesController.text),
                      maxUsesPerUser: int.tryParse(maxUsesPerUserController.text) ?? 1,
                      validTo: validTo,
                    );
                  } else {
                    await adminCreatePromotion(
                      name: name,
                      code: codeController.text.trim().isNotEmpty ? codeController.text.trim().toUpperCase() : null,
                      description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                      promoType: promoType,
                      discountType: discountType,
                      discountValue: discountValue,
                      maxDiscount: int.tryParse(maxDiscountController.text),
                      minOrderValue: int.tryParse(minOrderController.text) ?? 0,
                      maxTotalUses: int.tryParse(maxTotalUsesController.text),
                      maxUsesPerUser: int.tryParse(maxUsesPerUserController.text) ?? 1,
                      validTo: validTo,
                    );
                  }

                  ref.invalidate(adminPromotionsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Đã cập nhật khuyến mãi' : 'Đã tạo khuyến mãi mới'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Lưu' : 'Tạo'),
            ),
          ],
        ),
      ),
    );
  }
}
