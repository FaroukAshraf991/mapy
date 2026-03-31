import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static Future<WeatherData?> getWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
          '&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;

      if (current == null) return null;

      return WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        weatherCode: current['weather_code'] as int,
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static String getWeatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 49) return '🌫️';
    if (code <= 59) return '🌧️';
    if (code <= 69) return '🌨️';
    if (code <= 79) return '❄️';
    if (code <= 84) return '🌧️';
    if (code <= 94) return '🌨️';
    return '⛈️';
  }

  static String getWeatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 59) return 'Drizzle';
    if (code <= 69) return 'Rain';
    if (code <= 79) return 'Snow';
    if (code <= 84) return 'Rain showers';
    if (code <= 94) return 'Snow showers';
    return 'Thunderstorm';
  }
}

class WeatherData {
  final double temperature;
  final int weatherCode;
  final double windSpeed;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
  });

  String get icon => WeatherService.getWeatherIcon(weatherCode);
  String get description => WeatherService.getWeatherDescription(weatherCode);
  String get temperatureText => '${temperature.round()}°C';
}
