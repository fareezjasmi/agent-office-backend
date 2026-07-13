import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/services/weather_service.dart';

/// A simple inline mock HTTP client that delegates [send] to a callback.
class MockClient extends http.BaseClient {
  final Future<MockResponse> Function(http.BaseRequest request) handler;

  MockClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    final bodyBytes = Uint8List.fromList(utf8.encode(response.body));
    return http.StreamedResponse(
      Stream.value(bodyBytes),
      response.statusCode,
    );
  }
}

/// A simple response holder.
class MockResponse {
  final String body;
  final int statusCode;
  MockResponse(this.body, this.statusCode);
}

/// Builds a valid Open-Meteo geocoding response.
String _validGeocodingResponse({String name = 'London', String? admin1, String country = 'United Kingdom', double lat = 51.5, double lon = -0.13}) {
  final result = <String, dynamic>{
    'id': 2643743,
    'name': name,
    'latitude': lat,
    'longitude': lon,
    'country': country,
  };
  if (admin1 != null) {
    result['admin1'] = admin1;
  }
  return jsonEncode({'results': [result]});
}

/// Builds a valid Open-Meteo weather forecast response.
String _validWeatherResponse({double temp = 15.5, int humidity = 72, double windSpeed = 12.3, int weatherCode = 0}) {
  return jsonEncode({
    'current': {
      'temperature_2m': temp,
      'relative_humidity_2m': humidity,
      'wind_speed_10m': windSpeed,
      'weather_code': weatherCode,
    },
  });
}

void main() {
  group('WeatherService.getWeather', () {
    test('throws exception when city name is empty', () async {
      final service = WeatherService(client: MockClient((_) async {
        return MockResponse('', 200);
      }));

      expect(
        () => service.getWeather(''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Please enter a city name'),
        )),
      );
    });

    test('throws exception when city name contains only whitespace', () async {
      final service = WeatherService(client: MockClient((_) async {
        return MockResponse('', 200);
      }));

      expect(
        () => service.getWeather('   '),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Please enter a city name'),
        )),
      );
    });

    test('returns Weather on successful geocoding and weather API calls', () async {
      int callCount = 0;

      final service = WeatherService(
        client: MockClient((request) async {
          callCount++;
          final uri = request.url.toString();

          if (uri.contains('geocoding-api.open-meteo.com')) {
            return MockResponse(_validGeocodingResponse(), 200);
          } else if (uri.contains('api.open-meteo.com')) {
            return MockResponse(_validWeatherResponse(), 200);
          }

          return MockResponse('', 404);
        }),
      );

      final weather = await service.getWeather('London');

      expect(callCount, 2);
      expect(weather.cityName, 'London, United Kingdom');
      expect(weather.temperature, 15.5);
      expect(weather.humidity, 72);
      expect(weather.windSpeed, 12.3);
      expect(weather.condition, 'Sunny');
    });

    test('handles geocoding result without admin1 or country', () async {
      final service = WeatherService(
        client: MockClient((request) async {
          if (request.url.toString().contains('geocoding-api')) {
            return MockResponse(
              jsonEncode({
                'results': [
                  {'name': 'Metropolis', 'latitude': 40.0, 'longitude': -74.0},
                ],
              }),
              200,
            );
          }
          return MockResponse(_validWeatherResponse(), 200);
        }),
      );

      final weather = await service.getWeather('Metropolis');

      expect(weather.cityName, 'Metropolis');
    });

    test('throws City not found when geocoding returns empty results', () async {
      final service = WeatherService(
        client: MockClient((_) async {
          return MockResponse(jsonEncode({'results': []}), 200);
        }),
      );

      expect(
        () => service.getWeather('UnknownCity'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('City not found'),
        )),
      );
    });

    test('throws City not found when geocoding returns null results', () async {
      final service = WeatherService(
        client: MockClient((_) async {
          return MockResponse(jsonEncode({}), 200);
        }),
      );

      expect(
        () => service.getWeather('UnknownCity'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('City not found'),
        )),
      );
    });

    test('throws error when geocoding API fails with non-200', () async {
      final service = WeatherService(
        client: MockClient((_) async {
          return MockResponse('Server Error', 500);
        }),
      );

      expect(
        () => service.getWeather('London'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to find city'),
        )),
      );
    });

    test('throws error when weather API fails with non-200', () async {
      bool geocodingCalled = false;

      final service = WeatherService(
        client: MockClient((request) async {
          if (!geocodingCalled) {
            geocodingCalled = true;
            return MockResponse(_validGeocodingResponse(), 200);
          }
          return MockResponse('Bad Gateway', 502);
        }),
      );

      expect(
        () => service.getWeather('London'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to fetch weather data'),
        )),
      );
    });
  });
}
