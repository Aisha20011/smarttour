import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class WeatherData {
  final double temperature;
  final String description;
  final String icon;
  final String city;
  final double? humidity;
  final double? windSpeed;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.city,
    this.humidity,
    this.windSpeed,
  });

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'description': description,
      'icon': icon,
      'city': city,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class WeatherService {
  // OpenWeatherMap API - Free tier
  // Note: You need to get your own API key from https://openweathermap.org/api
  static const String _apiKey = '1407943a79e42a598039ae5a4ab8445c'; // Replace with your API key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get weather by city name
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?q=$cityName&appid=$_apiKey&units=metric&lang=ar',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = WeatherData(
          temperature: (data['main']['temp'] as num).toDouble(),
          description: data['weather'][0]['description'] ?? 'غير محدد',
          icon: data['weather'][0]['icon'] ?? '01d',
          city: data['name'] ?? cityName,
          humidity: (data['main']['humidity'] as num?)?.toDouble(),
          windSpeed: (data['wind']['speed'] as num?)?.toDouble(),
        );

        // Save to Firebase
        await _saveWeatherToFirestore(weatherData);

        return weatherData;
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      // Try to get cached data from Firebase
      return await _getCachedWeather(cityName);
    }
  }

  // Get weather by coordinates
  Future<WeatherData?> getWeatherByCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=ar',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = WeatherData(
          temperature: (data['main']['temp'] as num).toDouble(),
          description: data['weather'][0]['description'] ?? 'غير محدد',
          icon: data['weather'][0]['icon'] ?? '01d',
          city: data['name'] ?? 'موقعك',
          humidity: (data['main']['humidity'] as num?)?.toDouble(),
          windSpeed: (data['wind']['speed'] as num?)?.toDouble(),
        );

        // Save to Firebase
        await _saveWeatherToFirestore(weatherData);

        return weatherData;
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  // Save weather data to Firestore
  Future<void> _saveWeatherToFirestore(WeatherData weather) async {
    try {
      await _firestore.collection('weather_cache').doc(weather.city).set(
        weather.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error saving weather to Firestore: $e');
    }
  }

  // Get cached weather from Firestore
  Future<WeatherData?> _getCachedWeather(String cityName) async {
    try {
      final doc = await _firestore
          .collection('weather_cache')
          .doc(cityName)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return WeatherData(
          temperature: (data['temperature'] as num).toDouble(),
          description: data['description'] ?? 'غير محدد',
          icon: data['icon'] ?? '01d',
          city: data['city'] ?? cityName,
          humidity: (data['humidity'] as num?)?.toDouble(),
          windSpeed: (data['windSpeed'] as num?)?.toDouble(),
        );
      }
    } catch (e) {
      print('Error getting cached weather: $e');
    }
    return null;
  }

  // Get weather icon based on icon code
  static String getWeatherIcon(String iconCode) {
    // Map OpenWeatherMap icon codes to Flutter icons
    switch (iconCode) {
      case '01d': // clear sky day
        return '☀️';
      case '01n': // clear sky night
        return '🌙';
      case '02d': // few clouds day
      case '02n': // few clouds night
        return '⛅';
      case '03d': // scattered clouds
      case '03n':
      case '04d': // broken clouds
      case '04n':
        return '☁️';
      case '09d': // shower rain
      case '09n':
        return '🌦️';
      case '10d': // rain day
      case '10n': // rain night
        return '🌧️';
      case '11d': // thunderstorm
      case '11n':
        return '⛈️';
      case '13d': // snow
      case '13n':
        return '❄️';
      case '50d': // mist
      case '50n':
        return '🌫️';
      default:
        return '☀️';
    }
  }
}





