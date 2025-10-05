import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maps_google_v2/constants.dart';
import 'package:maps_google_v2/models/get_coordinates_from_placeid.dart';
import 'package:maps_google_v2/models/get_places.dart';
import 'package:maps_google_v2/models/place_from_coordinates.dart';

class ApiServices {
  // ------------------------
  // GOOGLE APIs
  // ------------------------

  Future<PlaceFromCoordinates> placeFromCoordinates(
    double lat,
    double lng,
  ) async {
    Uri url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${Constants.gcpKey}',
    );
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return PlaceFromCoordinates.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API ERROR: placeFromCoordinates');
    }
  }

  Future<GetPlaces> getPlaces(String placeName) async {
    Uri url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=${Constants.gcpKey}',
    );
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return GetPlaces.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API ERROR: getPlaces');
    }
  }

  Future<GetCoordinatesFromPlaceId> getCoordinatesFromPlaceId(
    String placeId,
  ) async {
    Uri url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=${Constants.gcpKey}',
    );
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return GetCoordinatesFromPlaceId.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API ERROR: getCoordinatesFromPlaceId');
    }
  }

  // ------------------------
  // FLASK API (Clima)
  // ------------------------

  static const String baseUrl =
      "http://192.168.60.57:5000"; // cambia por tu IP Flask

  Future<Map<String, dynamic>> obtenerClima(
    double lat,
    double lon,
    String fecha,
  ) async {
    final url = Uri.parse("$baseUrl/clima/$lat/$lon/$fecha");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("API ERROR: obtenerClima (${response.statusCode})");
    }
  }
}
