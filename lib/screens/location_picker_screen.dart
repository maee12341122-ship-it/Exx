import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../utils/constants.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPoint;
  const LocationPickerScreen({super.key, this.initialPoint});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _taizCenter = LatLng(13.5795, 44.0209);
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  LatLng? _selectedPoint;
  bool _gettingLocation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  Future<void> _useGps() async {
    setState(() {
      _gettingLocation = true;
      _error = null;
    });
    try {
      final position = await _locationService.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _selectedPoint = point);
      _mapController.move(point, 16);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحديد موقع التوصيل')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _gettingLocation ? null : _useGps,
                    icon: _gettingLocation
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: const Text('موقعي الحالي GPS'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedPoint == null ? 'اضغط على الخريطة لوضع المؤشر' : 'تم اختيار نقطة التوصيل',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
            ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialPoint ?? _taizCenter,
                initialZoom: widget.initialPoint == null ? 13 : 16,
                onTap: (tapPosition, point) => setState(() => _selectedPoint = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.taizexpress.taiz_express',
                ),
                if (_selectedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPoint!,
                        width: 52,
                        height: 52,
                        child: const Icon(Icons.location_pin, size: 48, color: Colors.red),
                      ),
                    ],
                  ),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface,
            child: FilledButton(
              onPressed: _selectedPoint == null ? null : () => Navigator.pop(context, _selectedPoint),
              child: const Text('تأكيد هذا الموقع'),
            ),
          ),
        ],
      ),
    );
  }
}
