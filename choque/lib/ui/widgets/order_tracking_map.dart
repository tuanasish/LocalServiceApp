import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import '../../config/constants.dart';
import '../../data/models/order_model.dart';
import '../../data/models/driver_location_model.dart';
import '../../providers/app_providers.dart';

/// Order Tracking Map Widget
///
/// Widget hiển thị map với markers cho pickup, dropoff, driver location
class OrderTrackingMapWidget extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderTrackingMapWidget({super.key, required this.order});

  @override
  ConsumerState<OrderTrackingMapWidget> createState() =>
      _OrderTrackingMapWidgetState();
}

class _OrderTrackingMapWidgetState
    extends ConsumerState<OrderTrackingMapWidget> {
  VietmapController? _controller;
  bool _markerAdded = false;

  void _updateMarkers(DriverLocationModel? driverLocation) async {
    if (_controller == null) return;

    // Clear existing symbols if necessary or just add them once
    if (!_markerAdded) {
      // Pickup (Store)
      await _controller!.addSymbol(
        SymbolOptions(
          geometry: LatLng(widget.order.pickup.lat, widget.order.pickup.lng),
          textField: 'Cửa hàng',
          textColor: Colors.blue,
          textOffset: const Offset(0, 2),
        ),
      );

      // Dropoff (Customer)
      await _controller!.addSymbol(
        SymbolOptions(
          geometry: LatLng(widget.order.dropoff.lat, widget.order.dropoff.lng),
          textField: 'Bạn',
          textColor: Colors.green,
          textOffset: const Offset(0, 2),
        ),
      );

      _markerAdded = true;
    }

    // Driver (updates frequently)
    if (driverLocation != null) {
      // For simplicity, we can remove previous driver symbol and add new one
      // In a real app, you'd track the symbol ID to update it
      await _controller!.clearSymbols();
      _markerAdded = false; // Re-add static markers next time

      // Re-add pickup/dropoff (due to clearSymbols)
      await _controller!.addSymbol(
        SymbolOptions(
          geometry: LatLng(widget.order.pickup.lat, widget.order.pickup.lng),
          textField: 'Cửa hàng',
        ),
      );
      await _controller!.addSymbol(
        SymbolOptions(
          geometry: LatLng(widget.order.dropoff.lat, widget.order.dropoff.lng),
          textField: 'Bạn',
        ),
      );

      await _controller!.addSymbol(
        SymbolOptions(
          geometry: LatLng(driverLocation.lat, driverLocation.lng),
          textField: 'Tài xế',
          textColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch driver location if assigned
    final driverId = widget.order.driverId;
    final driverLocationAsync = driverId != null
        ? ref.watch(specificDriverLocationProvider(driverId))
        : const AsyncValue<DriverLocationModel?>.data(null);

    // Call update markers when location changes
    if (_controller != null) {
      _updateMarkers(driverLocationAsync.value);
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            VietmapGL(
              onMapCreated: (controller) {
                _controller = controller;
                // Center map between pickup and dropoff
                final centerLat =
                    (widget.order.pickup.lat + widget.order.dropoff.lat) / 2;
                final centerLng =
                    (widget.order.pickup.lng + widget.order.dropoff.lng) / 2;
                controller.moveCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(centerLat, centerLng),
                    13.0,
                  ),
                );
                _updateMarkers(driverLocationAsync.value);
              },
              styleString:
                  'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${AppConstants.vietmapTilemapKey}',
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.order.pickup.lat,
                  widget.order.pickup.lng,
                ),
                zoom: 13.0,
              ),
            ),

            // Legend
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(
                      Icons.store_outlined,
                      Colors.blue,
                      'Cửa hàng',
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      Icons.person_outline,
                      Colors.green,
                      'Khách hàng',
                    ),
                    driverLocationAsync.when(
                      data: (location) => location != null
                          ? Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: _buildLegendItem(
                                Icons.local_shipping,
                                Colors.orange,
                                'Tài xế',
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
