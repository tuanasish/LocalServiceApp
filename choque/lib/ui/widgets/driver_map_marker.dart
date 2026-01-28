import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system.dart';
import '../../data/models/profile_model.dart';

/// Driver Map Marker
///
/// Custom marker widget for displaying drivers on map in monitoring screen.
class DriverMapMarker extends StatelessWidget {
  final ProfileModel driver;
  final bool isSelected;
  final VoidCallback? onTap;

  const DriverMapMarker({
    super.key,
    required this.driver,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(driver.driverStatus ?? 'offline');

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.motorcycle, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _getInitials(driver.fullName ?? 'D'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Pointer
          CustomPaint(
            size: const Size(12, 8),
            painter: _TrianglePainter(color: color),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return AppColors.success;
      case 'busy':
        return const Color(0xFFF59E0B); // Orange
      case 'offline':
      default:
        return AppColors.textSecondary;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'D';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

/// Triangle painter for marker pointer
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) =>
      color != oldDelegate.color;
}
