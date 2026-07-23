import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  
  // Cette fonction retourne un objet avec toutes les infos
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Vérifier si le GPS est allumé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Le GPS est désactivé.');
    }

    // 2. Vérifier les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permission refusée.');
      }
    }

    // 3. Obtenir la position exacte 
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );

    // 4. Traduire en Adresse 
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Exemple régional :
        // administrativeArea = région ou département
        // locality = ville ou commune
        
        return {
          "latitude": position.latitude,
          "longitude": position.longitude,
          "wilaya": place.administrativeArea ?? "",
          "commune": place.locality ?? "",
          "full_address": "${place.street}, ${place.locality}", // Adresse précise
        };
      }
    } catch (e) {
      print("Erreur Geocoding: $e");
    }
    return null;
  }
}