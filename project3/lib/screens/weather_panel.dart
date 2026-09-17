import 'package:flutter/material.dart';

import '../weather_service.dart';

class WeatherPanel extends StatefulWidget {
  const WeatherPanel({
    super.key,
    required this.service,
    required this.onChanged,
  });
  final WeatherService service;
  final ValueChanged<WeatherSnapshot?> onChanged;

  @override
  State<WeatherPanel> createState() => _WeatherPanelState();
}

class _WeatherPanelState extends State<WeatherPanel> {
  final _city = TextEditingController();
  List<WeatherCity> _results = [];
  WeatherSnapshot? _snapshot;
  String? _error;
  bool _busy = false;
  int _request = 0;

  Future<void> _search() async {
    if (_city.text.trim().length < 2) {
      setState(() => _error = 'Enter your city or postal code.');
      return;
    }
    final request = ++_request;
    setState(() {
      _busy = true;
      _error = null;
      _results = [];
    });
    try {
      final results = await widget.service.search(_city.text);
      if (!mounted || request != _request) return;
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _error = 'No cities found. Try adding your state or country.';
        }
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(
        () =>
            _error = 'City search failed. Check your connection and try again.',
      );
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  Future<void> _load(WeatherCity city) async {
    final request = ++_request;
    widget.onChanged(null);
    setState(() {
      _busy = true;
      _error = null;
      _snapshot = null;
    });
    try {
      final snapshot = await widget.service.current(city);
      if (!mounted || request != _request) return;
      setState(() {
        _snapshot = snapshot;
        _results = [];
      });
      widget.onChanged(snapshot);
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _error =
            'Could not load the temperature. Select your city below to retry.';
        _results = [city];
      });
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 12),
      const Text(
        'Enter the city you are currently in, then choose the matching location.',
      ),
      const SizedBox(height: 8),
      TextField(
        key: const ValueKey('city-input'),
        controller: _city,
        decoration: const InputDecoration(
          labelText: 'Your current city',
          hintText: 'City, state or country',
        ),
        onSubmitted: (_) {
          if (!_busy) _search();
        },
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          key: const ValueKey('search-city'),
          onPressed: _busy ? null : _search,
          child: Text(_busy ? 'Loading…' : 'Find city'),
        ),
      ),
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      for (final city in _results)
        TextButton(
          onPressed: _busy ? null : () => _load(city),
          child: Text(city.label),
        ),
      if (_snapshot != null) ...[
        Text(
          _snapshot!.city.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          'Include ${_snapshot!.answer} in your password (°F, rounded to the nearest whole degree).',
        ),
        Text('Weather time: ${_snapshot!.time.replaceFirst('T', ' ')} local'),
        const Text(
          'This temperature stays fixed for this game unless you refresh it.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _busy ? null : () => _load(_snapshot!.city),
            child: const Text('Refresh temperature'),
          ),
        ),
      ],
      const SizedBox(height: 8),
      const Text(
        'Weather: Open-Meteo • City data: GeoNames',
        style: TextStyle(fontSize: 12),
      ),
    ],
  );
}
