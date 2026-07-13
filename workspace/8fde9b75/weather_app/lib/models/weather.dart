class Weather {
  final String cityName;
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;
  final String icon;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    String? icon,
  }) : icon = icon ?? _iconForCondition(condition);

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['cityName'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      condition: json['condition'] as String,
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      icon: json['icon'] as String?,
    );
  }

  factory Weather.fromGeocodingResult(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final country = json['country'] as String? ?? '';
    final admin1 = json['admin1'] as String?;

    String cityName = name;
    if (admin1 != null && admin1.isNotEmpty) {
      cityName += ', $admin1';
    }
    if (country.isNotEmpty) {
      cityName += ', $country';
    }

    return Weather(
      cityName: cityName,
      temperature: 0,
      condition: 'No Data',
      humidity: 0,
      windSpeed: 0,
    );
  }

  factory Weather.fromWeatherForecast(
      Map<String, dynamic> json, String cityName) {
    final current = json['current'] as Map<String, dynamic>;
    final temperature = (current['temperature_2m'] as num).toDouble();
    final humidity = current['relative_humidity_2m'] as int;
    final windSpeed = (current['wind_speed_10m'] as num).toDouble();
    final weatherCode = current['weather_code'] as int;
    final condition = _conditionFromWeatherCode(weatherCode);

    return Weather(
      cityName: cityName,
      temperature: temperature,
      condition: condition,
      humidity: humidity,
      windSpeed: windSpeed,
    );
  }

  static String _conditionFromWeatherCode(int code) {
    switch (code) {
      case 0:
        return 'Sunny';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 'Rainy';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'Snowy';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Sunny';
    }
  }

  factory Weather.empty() {
    return Weather(
      cityName: '--',
      temperature: 0,
      condition: 'No Data',
      humidity: 0,
      windSpeed: 0,
      icon: '\u{1F324}\u{FE0F}',
    );
  }

  static String _iconForCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return '\u{2600}\u{FE0F}';
      case 'cloudy':
        return '\u{2601}\u{FE0F}';
      case 'rainy':
        return '\u{1F327}\u{FE0F}';
      case 'snowy':
        return '\u{2744}\u{FE0F}';
      case 'partly cloudy':
        return '\u{26C5}';
      case 'thunderstorm':
        return '\u{26C8}\u{FE0F}';
      case 'foggy':
        return '\u{1F32B}\u{FE0F}';
      case 'windy':
        return '\u{1F4A8}';
      default:
        return '\u{1F324}\u{FE0F}';
    }
  }

  Weather copyWith({
    String? cityName,
    double? temperature,
    String? condition,
    int? humidity,
    double? windSpeed,
    String? icon,
  }) {
    return Weather(
      cityName: cityName ?? this.cityName,
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      icon: icon ?? this.icon,
    );
  }
}
