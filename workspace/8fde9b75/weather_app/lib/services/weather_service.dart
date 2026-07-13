import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather.dart';

class WeatherService {
  final http.Client _httpClient;

  WeatherService({http.Client? client}) : _httpClient = client ?? http.Client();

  static const String _geocodingBaseUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String _weatherBaseUrl =
      'https://api.open-meteo.com/v1/forecast';
  static const Duration _timeout = Duration(seconds: 10);

  Future<Weather> getWeather(String cityName) async {
    final trimmed = cityName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please enter a city name');
    }

    try {
      // Step 1: Geocoding — convert city name to lat/lon
      final geocodingUri = Uri.parse(_geocodingBaseUrl).replace(
        queryParameters: {
          'name': trimmed,
          'count': '1',
          'language': 'en',
          'format': 'json',
        },
      );

      final geocodingResponse =
          await _httpClient.get(geocodingUri).timeout(_timeout);

      if (geocodingResponse.statusCode != 200) {
        throw Exception('Failed to find city. Please try again later.');
      }

      final geocodingData =
          jsonDecode(geocodingResponse.body) as Map<String, dynamic>;
      final results = geocodingData['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        throw Exception(
            'City not found. Please check the name and try again.');
      }

      final firstResult = results[0] as Map<String, dynamic>;
      final weatherFromGeocoding = Weather.fromGeocodingResult(firstResult);
      final lat = firstResult['latitude'];
      final lon = firstResult['longitude'];

      // Step 2: Weather — fetch current weather using lat/lon
      final weatherUri = Uri.parse(_weatherBaseUrl).replace(
        queryParameters: {
          'latitude': lat.toString(),
          'longitude': lon.toString(),
          'current':
              'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
          'timezone': 'auto',
        },
      );

      final weatherResponse =
          await _httpClient.get(weatherUri).timeout(_timeout);

      if (weatherResponse.statusCode != 200) {
        throw Exception(
            'Failed to fetch weather data. Please try again later.');
      }

      final weatherData =
          jsonDecode(weatherResponse.body) as Map<String, dynamic>;
      return Weather.fromWeatherForecast(
          weatherData, weatherFromGeocoding.cityName);
    } on TimeoutException {
      throw Exception(
          'Request timed out. Please check your internet connection.');
    } on http.ClientException {
      throw Exception(
          'Network error. Please check your internet connection.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }
}
