import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/constants.dart';
import '../../data/models/location_model.dart';
import '../../services/vietmap_api_service.dart';

/// ShopeeFood-style Map Address Picker Screen
/// 
/// Features:
/// - Search bar at top
/// - Map with custom marker
/// - FAB for current location
/// - Address suggestions list below map (draggable)
class MapAddressPickerScreen extends ConsumerStatefulWidget {
  final LocationModel? initialLocation;

  const MapAddressPickerScreen({
    super.key,
    this.initialLocation,
  });

  @override
  ConsumerState<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends ConsumerState<MapAddressPickerScreen> {
  VietmapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final VietmapApiService _apiService = VietmapApiService();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  
  LatLng _selectedLocation = const LatLng(20.00333, 105.97583); // Nga Sơn, Thanh Hóa
  String _selectedAddress = '';
  bool _isLoadingSuggestions = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearchMode = false;
  Timer? _searchDebounce;
  Timer? _suggestionDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.lat,
        widget.initialLocation!.lng,
      );
      _selectedAddress = widget.initialLocation!.address ?? widget.initialLocation!.label;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSuggestionsForLocation(_selectedLocation);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _suggestionDebounce?.cancel();
    _searchController.dispose();
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestionsForLocation(LatLng location) async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // Get reverse geocode for selected address
      final address = await _apiService.reverseGeocode(
        location.latitude,
        location.longitude,
      );
      
      // Get nearby suggestions
      final suggestions = await _apiService.searchAddress(
        '', // Empty query to get nearby places
        focusLat: location.latitude,
        focusLng: location.longitude,
      );
      
      setState(() {
        _selectedAddress = address ?? 'Không tìm thấy địa chỉ';
        _suggestions = suggestions.take(5).toList();
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _selectedAddress = 'Không tìm thấy địa chỉ';
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchMode = false;
      });
      return;
    }

    setState(() {
      _isSearchMode = true;
    });

    try {
      final results = await _apiService.searchAddress(
        query,
        focusLat: _selectedLocation.latitude,
        focusLng: _selectedLocation.longitude,
      );
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _onSearchResultTap(Map<String, dynamic> result) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final properties = result['properties'] as Map<String, dynamic>?;
    
    if (geometry != null) {
      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates != null && coordinates.length >= 2) {
        final lng = (coordinates[0] as num).toDouble();
        final lat = (coordinates[1] as num).toDouble();
        final location = LatLng(lat, lng);
        
        final addressFromResult = properties?['name'] as String? ?? 
                                  properties?['label'] as String? ?? 
                                  properties?['address'] as String? ?? 
                                  properties?['full_address'] as String?;
        
        setState(() {
          _selectedLocation = location;
          _searchResults = [];
          _isSearchMode = false;
          _searchController.clear();
          if (addressFromResult != null && addressFromResult.isNotEmpty) {
            _selectedAddress = addressFromResult;
          }
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(location, 16.0),
        );
        
        // Reload suggestions for new location
        _loadSuggestionsForLocation(location);
        
        // Collapse search results
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _onSuggestionTap(Map<String, dynamic> result) {
    _onSearchResultTap(result);
    // Return immediately with selected address
    _confirmSelection(result);
  }

  void _confirmSelection([Map<String, dynamic>? result]) {
    String address = _selectedAddress;
    double lat = _selectedLocation.latitude;
    double lng = _selectedLocation.longitude;
    
    if (result != null) {
      final geometry = result['geometry'] as Map<String, dynamic>?;
      final properties = result['properties'] as Map<String, dynamic>?;
      
      if (geometry != null) {
        final coordinates = geometry['coordinates'] as List<dynamic>?;
        if (coordinates != null && coordinates.length >= 2) {
          lng = (coordinates[0] as num).toDouble();
          lat = (coordinates[1] as num).toDouble();
        }
      }
      
      address = properties?['name'] as String? ?? 
                properties?['label'] as String? ?? 
                properties?['address'] as String? ?? 
                address;
    }
    
    final location = LocationModel(
      label: address,
      address: address,
      lat: lat,
      lng: lng,
    );
    
    if (mounted) {
      context.pop(location);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || 
            requested == LocationPermission.deniedForever) {
          return;
        }
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final location = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = location;
      });
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 16.0),
      );
      
      _loadSuggestionsForLocation(location);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            // Map takes full screen
            Column(
              children: [
                // Header with search
                _buildHeader(),
                
                // Map
                Expanded(
                  child: Stack(
                    children: [
                      VietmapGL(
                        key: const ValueKey('vietmap_address_picker'),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _mapController?.moveCamera(
                            CameraUpdate.newLatLngZoom(
                              _selectedLocation,
                              15.0,
                            ),
                          );
                        },
                        onCameraIdle: () {
                          // When map stops moving, update suggestions
                          _suggestionDebounce?.cancel();
                          _suggestionDebounce = Timer(const Duration(milliseconds: 500), () {
                            if (mounted && !_isSearchMode) {
                              // Note: VietmapGL doesn't expose camera position directly
                              // Using selected location which is updated on map creation
                            }
                          });
                        },
                        styleString: 'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${AppConstants.vietmapTilemapKey}',
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation,
                          zoom: 15.0,
                        ),
                        myLocationEnabled: true,
                        myLocationTrackingMode: MyLocationTrackingMode.none,
                      ),
                      
                      // Center marker (ShopeeFood style - avatar marker)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 36),
                          child: _buildCustomMarker(),
                        ),
                      ),
                      
                      // FAB for current location
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          onPressed: _getCurrentLocation,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.my_location,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Bottom Sheet with suggestions (ShopeeFood style)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.35,
              minChildSize: 0.15,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // "Địa chỉ gợi ý" header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'Địa chỉ gợi ý',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_isLoadingSuggestions) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const Divider(height: 1),
                      
                      // Suggestions list
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.isEmpty ? 1 : _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                          itemBuilder: (context, index) {
                            if (_suggestions.isEmpty) {
                              return _buildCurrentSelectionTile();
                            }
                            return _buildSuggestionTile(_suggestions[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Search results overlay
            if (_isSearchMode && _searchResults.isNotEmpty)
              Positioned(
                top: 70,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      return _buildSearchResultTile(_searchResults[index]);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm vị trí',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _isSearchMode = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) {
                  _searchDebounce?.cancel();
                  if (value.isEmpty) {
                    setState(() {
                      _searchResults = [];
                      _isSearchMode = false;
                    });
                    return;
                  }
                  setState(() => _isSearchMode = true);
                  _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                    if (mounted && value.isNotEmpty) {
                      _onSearch(value);
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCustomMarker() {
    // ShopeeFood-style marker with avatar
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.red[400],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _TrianglePainter(color: Colors.red[400]!),
        ),
      ],
    );
  }

  Widget _buildCurrentSelectionTile() {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
      ),
      title: Text(
        _selectedAddress.isNotEmpty ? _selectedAddress : 'Vị trí đã chọn',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Nhấn để xác nhận vị trí này',
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
      ),
      onTap: () => _confirmSelection(),
    );
  }

  Widget _buildSuggestionTile(Map<String, dynamic> result) {
    final properties = result['properties'] as Map<String, dynamic>?;
    final name = properties?['name'] as String? ?? 
                 properties?['label'] as String? ?? 
                 'Địa chỉ';
    final address = properties?['label'] as String? ??
                    properties?['address'] as String? ?? 
                    '';
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
      ),
      title: Text(
        name,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: address.isNotEmpty
          ? Text(
              address,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () => _onSuggestionTap(result),
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> result) {
    final properties = result['properties'] as Map<String, dynamic>?;
    final name = properties?['name'] as String? ?? 
                 properties?['label'] as String? ?? 
                 'Địa chỉ';
    final address = properties?['label'] as String? ??
                    properties?['address'] as String? ?? 
                    '';
    
    return ListTile(
      leading: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
      title: Text(
        name,
        style: GoogleFonts.inter(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: address.isNotEmpty && address != name
          ? Text(
              address,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () => _onSearchResultTap(result),
    );
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
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
