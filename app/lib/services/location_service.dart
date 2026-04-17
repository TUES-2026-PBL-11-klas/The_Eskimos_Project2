import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<Position>? _stream;

  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Stream<Position> positionStream() {
    _stream ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    );
    return _stream!;
  }

  Future<Position?> currentPosition() async {
    if (!await ensurePermission()) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}
