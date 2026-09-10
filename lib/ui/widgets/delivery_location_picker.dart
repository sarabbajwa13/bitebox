import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config/app_theme.dart';
import '../../services/geo_utils.dart';

/// Read-only map preview (order history/tracking me delivery location dikhane ke liye).
class LocationMapPreview extends StatelessWidget {
  final LatLng location;
  final double height;
  const LocationMapPreview({super.key, required this.location, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: location,
            initialZoom: 15,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bitebox.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: location,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Map picker for the delivery location.
///
/// - Pin screen-center pe fixed hai; map pan karke location move hoti hai.
/// - Store ka **radius circle** dikhta hai; center store radius ke bahar jaaye
///   to boundary pe snap back ho jaata hai (radius ke andar hi select ho sake).
/// - "Use my current location" button GPS/browser location fetch karta hai.
class DeliveryLocationPicker extends StatefulWidget {
  final LatLng store;
  final double radiusKm;
  final LatLng? initial;
  final ValueChanged<LatLng> onChanged;

  const DeliveryLocationPicker({
    super.key,
    required this.store,
    required this.radiusKm,
    required this.onChanged,
    this.initial,
  });

  @override
  State<DeliveryLocationPicker> createState() => _DeliveryLocationPickerState();
}

class _DeliveryLocationPickerState extends State<DeliveryLocationPicker> {
  final MapController _controller = MapController();
  static const Distance _d = Distance();

  bool _clamping = false;
  bool _gpsLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initial != null) {
        _controller.move(widget.initial!, _controller.camera.zoom);
      } else {
        _useCurrentLocation();
      }
    });
  }

  LatLngBounds get _radiusBounds {
    final m = widget.radiusKm * 1000 * 1.2;
    return LatLngBounds(
      _d.offset(widget.store, m, 45),
      _d.offset(widget.store, m, 225),
    );
  }

  void _setSelected(LatLng p) => widget.onChanged(p);

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (_clamping) return;
    final center = camera.center;
    final clamped = GeoUtils.clampToRadius(
      widget.store,
      center,
      widget.radiusKm,
    );
    if (GeoUtils.distanceKm(center, clamped) > 0.002) {
      // Radius ke bahar — boundary pe snap back.
      _clamping = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.move(clamped, camera.zoom);
        _clamping = false;
      });
      _setSelected(clamped);
    } else {
      _setSelected(center);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gpsLoading = true);
    final loc = await GeoUtils.getCurrentLocation();
    if (!mounted) return;
    setState(() => _gpsLoading = false);
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location access denied — please pick on the map'),
        ),
      );
      return;
    }
    final clamped = GeoUtils.clampToRadius(widget.store, loc, widget.radiusKm);
    _controller.move(clamped, _controller.camera.zoom);
    _setSelected(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: _radiusBounds,
                  padding: const EdgeInsets.all(20),
                ),
                minZoom: 10,
                maxZoom: 18,
                onPositionChanged: _onPositionChanged,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bitebox.app',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: widget.store,
                      radius: widget.radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderColor: AppColors.primary.withValues(alpha: 0.5),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                // Store marker.
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.store,
                      width: 26,
                      height: 26,
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primaryDark,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Fixed center delivery pin (tip points at map center).
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: const Icon(
                    Icons.location_pin,
                    size: 46,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
            // "Use my current location" button.
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _gpsLoading ? null : _useCurrentLocation,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _gpsLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primaryDark,
                          ),
                  ),
                ),
              ),
            ),
            // Attribution (OSM requires it).
            const Positioned(
              left: 6,
              bottom: 4,
              child: Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
