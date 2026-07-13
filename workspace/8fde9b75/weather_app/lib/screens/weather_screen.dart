import 'package:flutter/material.dart';
import 'package:weather_app/models/weather.dart';
import 'package:weather_app/services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

enum _ScreenState { empty, loading, error, populated }

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherService _weatherService = WeatherService();

  _ScreenState _state = _ScreenState.empty;
  Weather? _weather;
  String? _errorMessage;
  String? _lastSearchedCity;

  void _fetchWeather(String cityName) {
    final trimmed = cityName.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = 'Please enter a city name';
      });
      return;
    }

    setState(() {
      _state = _ScreenState.loading;
      _lastSearchedCity = trimmed;
    });

    _weatherService.getWeather(trimmed).then((weather) {
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _state = _ScreenState.populated;
      });
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _state = _ScreenState.error;
      });
    });
  }

  void _retry() {
    if (_lastSearchedCity != null && _lastSearchedCity!.isNotEmpty) {
      _fetchWeather(_lastSearchedCity!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Color> _getGradientColors(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return [const Color(0xFFFF8C00), const Color(0xFFFFD700)];
      case 'rainy':
        return [const Color(0xFF4A90D9), const Color(0xFF8B9DC3)];
      case 'cloudy':
        return [const Color(0xFF6B7B8D), const Color(0xFFA0AAB5)];
      case 'snowy':
        return [const Color(0xFF87CEEB), const Color(0xFFE0F7FA)];
      case 'partly cloudy':
        return [const Color(0xFFF4A460), const Color(0xFFB0C4DE)];
      case 'thunderstorm':
        return [const Color(0xFF2C3E50), const Color(0xFF4A5568)];
      case 'foggy':
        return [const Color(0xFF9E9E9E), const Color(0xFFCFD8DC)];
      case 'windy':
        return [const Color(0xFF7CB342), const Color(0xFFAED581)];
      default:
        return [const Color(0xFF4FC3F7), const Color(0xFF81D4FA)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _weather != null
                ? _getGradientColors(_weather!.condition)
                : [const Color(0xFF4FC3F7), const Color(0xFF81D4FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              if (_lastSearchedCity != null) _buildLastSearchedLabel(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) {
          _fetchWeather(value);
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search city...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon:
              Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
          suffixIcon: IconButton(
            icon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.9)),
            onPressed: () {
              _fetchWeather(_searchController.text);
            },
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLastSearchedLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Showing weather for: $_lastSearchedCity',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.empty:
        return _buildEmptyState();
      case _ScreenState.loading:
        return _buildLoadingState();
      case _ScreenState.error:
        return _buildErrorState();
      case _ScreenState.populated:
        return _buildPopulatedState();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '\u{1F324}\u{FE0F}',
            style: TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),
          const Text(
            'Weather Office',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a city to see the weather',
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Fetching weather...',
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '\u{26A0}\u{FE0F}',
              style: TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulatedState() {
    final weather = _weather!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // City name
          Text(
            weather.cityName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weather.condition,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),
          // Temperature and icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${weather.temperature.toStringAsFixed(0)}°C',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                weather.icon,
                style: const TextStyle(fontSize: 64),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDetailCard('\u{1F4A7}', '${weather.humidity}%', 'Humidity'),
              _buildDetailCard('\u{1F4A8}', '${weather.windSpeed.toStringAsFixed(0)} km/h', 'Wind Speed'),
              _buildDetailCard(
                weather.icon,
                weather.condition,
                'Condition',
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String icon, String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
