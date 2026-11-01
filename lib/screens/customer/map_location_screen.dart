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
  LatLng selectedPoint = const LatLng(13.5779, 44.0219); // تعز الافتراضية
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController(text: 'تعز - شارع جمال الرئيسي');
  bool isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خدمة الموقع (GPS) متوقفة.')));
        setState(() => isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض صلاحية الوصول للموقع')));
          setState(() => isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        selectedPoint = currentLatLng;
        isLoading = false;
        _addressController.text = 'تعز - الموقع الحالي GPS المباشر';
      });

      _mapController.move(currentLatLng, 16.0);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديد الموقع: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFC71538),
          title: const Text('موقعك على الخريطة', style: TextStyle(color: Colors.white)),
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: selectedPoint,
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    selectedPoint = point;
                    _addressController.text = 'تعز - منطقة تم اختيارها يدوياً على الخريطة';
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.taiz.express',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedPoint,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 45),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 20,
              left: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.my_location, color: Color(0xFFC71538)),
              ),
            ),
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFC71538))),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'العنوان النصي للموقع',
                        prefixIcon: const Icon(Icons.home, color: Color(0xFFC71538)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text('اختر موقعك لتأكيد التوصيل بدقة', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_addressController.text.isNotEmpty) {
                          Navigator.pop(context, _addressController.text);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسم العنوان')));
                        }
                      },
                      child: const Text('حفظ الموقع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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