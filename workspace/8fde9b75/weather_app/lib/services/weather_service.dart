import 'dart:math';

import 'package:weather_app/models/weather.dart';

class WeatherService {
  static final List<Weather> _presetCities = [
    Weather(
      cityName: 'London',
      temperature: 15,
      condition: 'Cloudy',
      humidity: 72,
      windSpeed: 18,
    ),
    Weather(
      cityName: 'Tokyo',
      temperature: 22,
      condition: 'Partly Cloudy',
      humidity: 65,
      windSpeed: 12,
    ),
    Weather(
      cityName: 'New York',
      temperature: 28,
      condition: 'Sunny',
      humidity: 55,
      windSpeed: 10,
    ),
    Weather(
      cityName: 'Sydney',
      temperature: 26,
      condition: 'Sunny',
      humidity: 60,
      windSpeed: 15,
    ),
    Weather(
      cityName: 'Mumbai',
      temperature: 32,
      condition: 'Rainy',
      humidity: 85,
      windSpeed: 8,
    ),
    Weather(
      cityName: 'Cairo',
      temperature: 38,
      condition: 'Sunny',
      humidity: 20,
      windSpeed: 14,
    ),
  ];

  static final List<String> _conditions = [
    'Sunny',
    'Cloudy',
    'Rainy',
    'Snowy',
    'Partly Cloudy',
    'Foggy',
    'Windy',
    'Thunderstorm',
  ];

  static final Random _random = Random();

  Future<Weather> getWeather(String cityName) async {
    final trimmed = cityName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please enter a city name');
    }

    // Simulate 1.5s network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // 10% chance of simulated network error
    if (_random.nextDouble() < 0.1) {
      throw Exception('Network error: Unable to connect to weather service');
    }

    final query = trimmed.toLowerCase();

    // Look for a fuzzy match (city name contains the query)
    for (final city in _presetCities) {
      if (city.cityName.toLowerCase().contains(query)) {
        return city;
      }
    }

    // No preset found, generate random plausible weather
    return _generateRandomWeather(trimmed);
  }

  Weather _generateRandomWeather(String cityName) {
    final temp = 0.0 + _random.nextDouble() * 40;
    final condition = _conditions[_random.nextInt(_conditions.length)];
    final humidity = _random.nextInt(71) + 20; // 20-90
    final windSpeed = 0.0 + _random.nextDouble() * 40;

    return Weather(
      cityName: cityName,
      temperature: double.parse(temp.toStringAsFixed(1)),
      condition: condition,
      humidity: humidity,
      windSpeed: double.parse(windSpeed.toStringAsFixed(1)),
    );
  }
}
