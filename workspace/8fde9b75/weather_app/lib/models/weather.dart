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
