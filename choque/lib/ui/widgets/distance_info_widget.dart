import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/location_model.dart';
import '../../providers/app_providers.dart';
import '../../services/distance_calculator_service.dart';
import '../../ui/design_system.dart';

/// Widget hiển thị khoảng cách và thời gian dự kiến giữa 2 điểm
class DistanceInfoWidget extends ConsumerWidget {
  final LocationModel pickup;
  final LocationModel dropoff;
  final TextStyle? textStyle;

  const DistanceInfoWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, double>>(
      future: ref
          .read(distanceCalculatorProvider)
          .getDistanceBetweenLocations(pickup, dropoff),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              _buildInfoColumn('Khoảng cách', '...'),
              const SizedBox(width: 16),
              _buildInfoColumn('Thời gian dự kiến', '...'),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Row(
            children: [
              _buildInfoColumn('Khoảng cách', '--'),
              const SizedBox(width: 16),
              _buildInfoColumn('Thời gian dự kiến', '--'),
            ],
          );
        }

        final data = snapshot.data!;
        final distance = data['distance'] ?? 0;
        final duration = data['duration'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildInfoColumn(
                'Khoảng cách',
                DistanceCalculatorService.formatDistance(distance),
              ),
            ),
            Expanded(
              child: _buildInfoColumn(
                'Thời gian dự kiến',
                DistanceCalculatorService.formatDuration(duration),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
