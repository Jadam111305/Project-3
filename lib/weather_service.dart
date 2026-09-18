import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherCity {
  const WeatherCity(this.label, this.latitude, this.longitude);
  final String label;
  final double latitude;
  final double longitude;
}

class WeatherSnapshot {
  const WeatherSnapshot(this.city, this.fahrenheit, this.time);
  final WeatherCity city;
  final double fahrenheit;
  final String time;
  int get answer => fahrenheit.round();
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('Weather service unavailable.');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map<String, dynamic> || json['error'] == true) {
      throw const FormatException('Invalid weather response.');
    }
    return json;
  }

  Future<List<WeatherCity>> search(String city) async {
    final data = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': city.trim(),
        'count': '5',
        'language': 'en',
        'format': 'json',
      }),
    );
    return (data['results'] as List? ?? []).map((item) {
      final names = [
        item['name'],
        item['admin1'],
        item['country'],
      ].whereType<String>().where((name) => name.isNotEmpty).toSet();
      return WeatherCity(
        names.join(', '),
        (item['latitude'] as num).toDouble(),
        (item['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  Future<WeatherSnapshot> current(WeatherCity city) async {
    final data = await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': city.latitude.toString(),
        'longitude': city.longitude.toString(),
        'current': 'temperature_2m',
        'temperature_unit': 'fahrenheit',
        'timezone': 'auto',
      }),
    );
    final current = data['current'];
    final units = data['current_units'];
    if (current is! Map ||
        current['temperature_2m'] is! num ||
        current['time'] is! String ||
        units is! Map ||
        units['temperature_2m'] != '°F') {
      throw const FormatException('Missing Fahrenheit temperature.');
    }
    final temperature = (current['temperature_2m'] as num).toDouble();
    if (!temperature.isFinite) {
      throw const FormatException('Invalid temperature.');
    }
    return WeatherSnapshot(city, temperature, current['time'] as String);
  }

  void close() => _client.close();
}
