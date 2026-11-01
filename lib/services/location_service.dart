import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('خدمة الموقع GPS مغلقة. فعّلها من إعدادات الهاتف.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('لم تسمح للتطبيق باستخدام الموقع.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('تم منع إذن الموقع نهائياً. افتح إعدادات التطبيق واسمح بالموقع.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }
}
