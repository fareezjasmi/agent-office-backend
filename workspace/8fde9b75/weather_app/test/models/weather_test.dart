import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/weather.dart';

void main() {
  group('Weather.fromJson', () {
    test('creates correct instance from JSON map', () {
      final json = {
        'cityName': 'London',
        'temperature': 15.5,
        'condition': 'Cloudy',
        'humidity': 72,
        'windSpeed': 12.3,
        'icon': '\u{2601}\u{FE0F}',
      };

      final weather = Weather.fromJson(json);

      expect(weather.cityName, 'London');
      expect(weather.temperature, 15.5);
      expect(weather.condition, 'Cloudy');
      expect(weather.humidity, 72);
      expect(weather.windSpeed, 12.3);
      expect(weather.icon, '\u{2601}\u{FE0F}');
    });

    test('creates correct instance without explicit icon', () {
      final json = {
        'cityName': 'Paris',
        'temperature': 22.0,
        'condition': 'Sunny',
        'humidity': 50,
        'windSpeed': 5.0,
      };

      final weather = Weather.fromJson(json);

      expect(weather.cityName, 'Paris');
      expect(weather.icon, '\u{2600}\u{FE0F}'); // auto-populated
    });

    test('handles integer temperature and windSpeed', () {
      final json = {
        'cityName': 'Tokyo',
        'temperature': 18,
        'condition': 'Rainy',
        'humidity': 80,
        'windSpeed': 10,
      };

      final weather = Weather.fromJson(json);

      expect(weather.temperature, 18.0);
      expect(weather.windSpeed, 10.0);
    });
  });

  group('Weather.fromGeocodingResult', () {
    test('extracts city name with admin1 and country', () {
      final json = {
        'name': 'Berlin',
        'admin1': 'Land Berlin',
        'country': 'Germany',
      };

      final weather = Weather.fromGeocodingResult(json);

      expect(weather.cityName, 'Berlin, Land Berlin, Germany');
      expect(weather.temperature, 0);
      expect(weather.condition, 'No Data');
      expect(weather.humidity, 0);
      expect(weather.windSpeed, 0);
    });

    test('extracts city name with country only', () {
      final json = {
        'name': 'Rome',
        'country': 'Italy',
      };

      final weather = Weather.fromGeocodingResult(json);

      expect(weather.cityName, 'Rome, Italy');
    });

    test('extracts city name with admin1 only', () {
      final json = {
        'name': 'Mumbai',
        'admin1': 'Maharashtra',
      };

      final weather = Weather.fromGeocodingResult(json);

      expect(weather.cityName, 'Mumbai, Maharashtra');
    });

    test('extracts city name without admin1 or country', () {
      final json = {
        'name': 'Metropolis',
      };

      final weather = Weather.fromGeocodingResult(json);

      expect(weather.cityName, 'Metropolis');
    });

    test('handles empty name gracefully', () {
      final json = <String, dynamic>{};

      final weather = Weather.fromGeocodingResult(json);

      expect(weather.cityName, '');
    });
  });

  group('Weather.fromWeatherForecast', () {
    Weather buildWeatherFromCode(int weatherCode) {
      final json = {
        'current': {
          'temperature_2m': 21.3,
          'relative_humidity_2m': 65,
          'wind_speed_10m': 8.2,
          'weather_code': weatherCode,
        },
      };
      return Weather.fromWeatherForecast(json, 'TestCity');
    }

    test('parses Open-Meteo current weather block correctly', () {
      final json = {
        'current': {
          'temperature_2m': 21.3,
          'relative_humidity_2m': 65,
          'wind_speed_10m': 8.2,
          'weather_code': 0,
        },
      };

      final weather = Weather.fromWeatherForecast(json, 'TestCity');

      expect(weather.cityName, 'TestCity');
      expect(weather.temperature, 21.3);
      expect(weather.humidity, 65);
      expect(weather.windSpeed, 8.2);
    });

    test('maps code 0 to Sunny', () {
      final weather = buildWeatherFromCode(0);
      expect(weather.condition, 'Sunny');
    });

    test('maps code 2 to Partly Cloudy', () {
      final weather = buildWeatherFromCode(2);
      expect(weather.condition, 'Partly Cloudy');
    });

    test('maps code 3 to Cloudy', () {
      final weather = buildWeatherFromCode(3);
      expect(weather.condition, 'Cloudy');
    });

    test('maps code 45 to Foggy', () {
      final weather = buildWeatherFromCode(45);
      expect(weather.condition, 'Foggy');
    });

    test('maps code 48 to Foggy', () {
      final weather = buildWeatherFromCode(48);
      expect(weather.condition, 'Foggy');
    });

    test('maps code 61 to Rainy', () {
      final weather = buildWeatherFromCode(61);
      expect(weather.condition, 'Rainy');
    });

    test('maps code 71 to Snowy', () {
      final weather = buildWeatherFromCode(71);
      expect(weather.condition, 'Snowy');
    });

    test('maps code 95 to Thunderstorm', () {
      final weather = buildWeatherFromCode(95);
      expect(weather.condition, 'Thunderstorm');
    });

    test('maps code 99 to Thunderstorm', () {
      final weather = buildWeatherFromCode(99);
      expect(weather.condition, 'Thunderstorm');
    });

    test('maps unknown code 999 to Sunny (default)', () {
      final weather = buildWeatherFromCode(999);
      expect(weather.condition, 'Sunny');
    });
  });

  group('Weather.empty', () {
    test('returns placeholder data', () {
      final weather = Weather.empty();

      expect(weather.cityName, '--');
      expect(weather.temperature, 0);
      expect(weather.condition, 'No Data');
      expect(weather.humidity, 0);
      expect(weather.windSpeed, 0);
      expect(weather.icon, '\u{1F324}\u{FE0F}');
    });
  });

  group('Weather.copyWith', () {
    test('preserves all fields when no arguments given', () {
      final original = Weather(
        cityName: 'London',
        temperature: 15.0,
        condition: 'Cloudy',
        humidity: 70,
        windSpeed: 10.0,
      );

      final copy = original.copyWith();

      expect(copy.cityName, 'London');
      expect(copy.temperature, 15.0);
      expect(copy.condition, 'Cloudy');
      expect(copy.humidity, 70);
      expect(copy.windSpeed, 10.0);
      expect(copy.icon, '\u{2601}\u{FE0F}');
    });

    test('updates specified fields', () {
      final original = Weather(
        cityName: 'London',
        temperature: 15.0,
        condition: 'Cloudy',
        humidity: 70,
        windSpeed: 10.0,
      );

      final copy = original.copyWith(
        temperature: 20.0,
        condition: 'Sunny',
      );

      expect(copy.cityName, 'London');
      expect(copy.temperature, 20.0);
      expect(copy.condition, 'Sunny');
      expect(copy.humidity, 70);
      expect(copy.windSpeed, 10.0);
    });

    test('keeps same icon when condition changes without passing icon', () {
      final original = Weather(
        cityName: 'London',
        temperature: 15.0,
        condition: 'Cloudy',
        humidity: 70,
        windSpeed: 10.0,
      );

      final copy = original.copyWith(condition: 'Rainy');

      // copyWith does not auto-recalculate icon; icon stays as the original
      expect(copy.condition, 'Rainy');
      expect(copy.icon, original.icon);
    });

    test('updates icon when passed explicitly', () {
      final original = Weather(
        cityName: 'London',
        temperature: 15.0,
        condition: 'Cloudy',
        humidity: 70,
        windSpeed: 10.0,
      );

      final copy = original.copyWith(
        condition: 'Rainy',
        icon: '\u{1F327}\u{FE0F}',
      );

      expect(copy.condition, 'Rainy');
      expect(copy.icon, '\u{1F327}\u{FE0F}');
    });
  });

  group('Weather.icon auto-population', () {
    test('Sunny condition maps to sun emoji', () {
      final weather = Weather(
        cityName: 'A',
        temperature: 0,
        condition: 'Sunny',
        humidity: 0,
        windSpeed: 0,
      );
      expect(weather.icon, '\u{2600}\u{FE0F}');
    });

    test('Cloudy condition maps to cloud emoji', () {
      final weather = Weather(
        cityName: 'A',
        temperature: 0,
        condition: 'Cloudy',
        humidity: 0,
        windSpeed: 0,
      );
      expect(weather.icon, '\u{2601}\u{FE0F}');
    });

    test('Rainy condition maps to rain emoji', () {
      final weather = Weather(
        cityName: 'A',
        temperature: 0,
        condition: 'Rainy',
        humidity: 0,
        windSpeed: 0,
      );
      expect(weather.icon, '\u{1F327}\u{FE0F}');
    });

    test('Snowy condition maps to snowflake emoji', () {
      final weather = Weather(
        cityName: 'A',
        temperature: 0,
        condition: 'Snowy',
        humidity: 0,
        windSpeed: 0,
      );
      expect(weather.icon, '\u{2744}\u{FE0F}');
    });

    test('Thunderstorm condition maps to storm emoji', () {
      final weather = Weather(
        cityName: 'A',
        temperature: 0,
        condition: 'Thunderstorm',
        humidity: 0,
        windSpeed: 0,
      );
      expect(weather.icon, '\u{26C8}\u{FE0F}');
    });

    test('Foggy condition maps to fog emoji', () {
      final weather = Weather(
        cityName: 'A',
        temperature: 0,
        condition: 'Foggy',
        humidity: 0,
        windSpeed: 0,
      );
      expect(weather.icon, '\u{1F32B}\u{FE0F}');
    });

    test('unknown condition maps to default emoji', () {
      final weather = Weather(
        cityName: 'A',
        temperature: 0,
        condition: 'Unknown',
        humidity: 0,
        windSpeed: 0,
      );
      expect(weather.icon, '\u{1F324}\u{FE0F}');
    });
  });
}
