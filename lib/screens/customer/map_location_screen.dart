import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapLocationScreen extends StatefulWidget {
  const MapLocationScreen({Key? key}) : super(key: key);

  @override
  State<MapLocationScreen> createState() => _MapLocationScreenState();
}

class _MapLocationScreenState extends State<MapLocationScreen> {
  // إحداثيات مدينة تعز الافتراضية (منطقة جولت سينان / شارع جمال)
  LatLng _currentCenter = const LatLng(13.5779, 44.0219);
  final MapController _mapController = MapController();
  String _selectedLocationName = 'تعز - شارع جمال الرئيسي';
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // دالة جلب الموقع الحالي للجهاز عبر الـ GPS
  Future<void> _determinePosition() async {
    setState(() => _isLoadingGps = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingGps = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingGps = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingGps = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _selectedLocationName = 'موقعي الحالي (تعز - ديلوكس / الروضة)';
        _isLoadingGps = false;
      });
      _mapController.move(_currentCenter, 16.0);
    } catch (e) {
      setState(() => _isLoadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A237E),
          title: const Text('حدد موقعك بدقة على الخريطة', style: TextStyle(color: Colors.white, fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context, _selectedLocationName),
          ),
        ),
        body: Stack(
          children: [
            // خريطة OpenStreetMap مع دعم تفاصيل أحياء تعز
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 15.0,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture && position.center != null) {
                    setState(() {
                      _currentCenter = position.center!;
                      _selectedLocationName = 'تعز (خط عرض: ${_currentCenter.latitude.toStringAsFixed(4)}, خط طول: ${_currentCenter.longitude.toStringAsFixed(4)})';
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.taiz.express',
                ),
              ],
            ),

            // دبوس التحديد في منتصف الشاشة
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, size: 50, color: Colors.redAccent),
              ),
            ),

            // زر تحديد الموقع الحالي (GPS)
            Positioned(
              top: 20,
              left: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.amber[700],
                child: _isLoadingGps 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Icon(Icons.my_location, color: Colors.black),
                onPressed: _determinePosition,
              ),
            ),

            // شريط العنوان السفلي مع زر التأكيد
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.home, color: Colors.amberAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedLocationName,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context, _selectedLocationName);
                      },
                      child: const Text('تثبيت هذا الموقع وعودة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
}
