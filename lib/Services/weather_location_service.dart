// weather_location_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class WeatherLocationService extends GetxService {
  final RxString location = 'Loading...'.obs;
  final RxString temperature = '--°C'.obs;
  final RxString weatherIcon = '☀️'.obs;
  final RxBool isLoading = true.obs;

  Future<WeatherLocationService> init() async {
    await fetchLocationAndWeather();
    // Update every 30 minutes
    Timer.periodic(Duration(minutes: 30), (timer) => fetchLocationAndWeather());
    return this;
  }

  Future<void> fetchLocationAndWeather() async {
    try {
      isLoading(true);
      final position = await _getCurrentPosition();
      await _fetchWeather(position.latitude, position.longitude);
      await _fetchLocationName(position.latitude, position.longitude);
    } catch (e) {
      location.value = 'Location unavailable';
      temperature.value = '--°C';
      weatherIcon.value = '❓';
      print('Error fetching weather/location: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    const apiKey = "e6689a54ecaad9c28ab77067b792a232";
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      temperature.value = '${data['main']['temp'].round()}°C';
      weatherIcon.value = _getWeatherIcon(data['weather'][0]['id']);
    } else {
      throw Exception('Failed to load weather');
    }
  }

  Future<void> _fetchLocationName(double lat, double lon) async {
    final response = await http.get(Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      location.value = data['city'] ?? data['locality'] ?? 'Your location';
    } else {
      throw Exception('Failed to load location name');
    }
  }

  String _getWeatherIcon(int weatherId) {
    if (weatherId >= 200 && weatherId < 300) return '⛈️'; // Thunderstorm
    if (weatherId >= 300 && weatherId < 600) return '🌧️'; // Drizzle/Rain
    if (weatherId >= 600 && weatherId < 700) return '❄️'; // Snow
    if (weatherId >= 700 && weatherId < 800) return '🌫️'; // Atmosphere
    if (weatherId == 800) return '☀️'; // Clear sky
    return '☁️'; // Default/cloudy
  }
}