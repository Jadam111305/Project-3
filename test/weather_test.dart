import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project3/screens/weather_panel.dart';
import 'package:project3/weather_service.dart';

const city = WeatherCity('Chicago, Illinois, United States', 41.85, -87.65);

http.Response weatherResponse({String unit = '°F'}) => http.Response(
  jsonEncode({
    'current_units': {'temperature_2m': unit},
    'current': {'temperature_2m': 71.6, 'time': '2026-09-17T12:00'},
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'search encodes city and current weather explicitly requests Fahrenheit',
    () async {
      final service = WeatherService(
        client: MockClient((request) async {
          if (request.url.host.startsWith('geocoding')) {
            expect(request.url.queryParameters['name'], 'Chicago, IL');
            return http.Response(
              jsonEncode({
                'results': [
                  {
                    'name': 'Chicago',
                    'admin1': 'Illinois',
                    'country': 'United States',
                    'latitude': 41.85,
                    'longitude': -87.65,
                  },
                ],
              }),
              200,
            );
          }
          expect(request.url.queryParameters['temperature_unit'], 'fahrenheit');
          expect(request.url.queryParameters['current'], 'temperature_2m');
          expect(request.url.queryParameters['latitude'], '41.85');
          return weatherResponse();
        }),
      );
      addTearDown(service.close);
      final cities = await service.search('Chicago, IL');
      expect(cities.single.label, city.label);
      final result = await service.current(cities.single);
      expect(result.answer, 72);
      expect(result.time, '2026-09-17T12:00');
    },
  );

  test(
    'no city results is handled; wrong units and missing data cannot pass',
    () async {
      final empty = WeatherService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(empty.close);
      expect(await empty.search('nowhere'), isEmpty);
      await expectLater(empty.current(city), throwsFormatException);
      final celsius = WeatherService(
        client: MockClient((_) async => weatherResponse(unit: '°C')),
      );
      addTearDown(celsius.close);
      await expectLater(celsius.current(city), throwsFormatException);
      final unavailable = WeatherService(
        client: MockClient((_) async => http.Response('', 503)),
      );
      addTearDown(unavailable.close);
      await expectLater(unavailable.current(city), throwsFormatException);
    },
  );

  testWidgets(
    'temperature lookup shows error, retries, and reports rounded answer',
    (tester) async {
      var attempts = 0;
      final service = WeatherService(
        client: MockClient((request) async {
          if (request.url.host.startsWith('geocoding')) {
            return http.Response(
              jsonEncode({
                'results': [
                  {
                    'name': 'Chicago',
                    'admin1': 'Illinois',
                    'country': 'United States',
                    'latitude': 41.85,
                    'longitude': -87.65,
                  },
                ],
              }),
              200,
            );
          }
          if (attempts++ == 0) return http.Response('unavailable', 503);
          return weatherResponse();
        }),
      );
      addTearDown(service.close);
      WeatherSnapshot? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeatherPanel(
                service: service,
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('city-input')),
        'Chicago',
      );
      await tester.tap(find.byKey(const ValueKey('search-city')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(city.label));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.textContaining('Could not load'), findsOneWidget);
      await tester.tap(find.text(city.label));
      await tester.pumpAndSettle();
      expect(selected?.answer, 72);
      expect(find.textContaining('Include 72'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late weather responses after navigation do not update a disposed panel',
    (tester) async {
      final pending = Completer<http.Response>();
      final service = WeatherService(client: MockClient((_) => pending.future));
      addTearDown(service.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherPanel(service: service, onChanged: (_) {}),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('city-input')),
        'Chicago',
      );
      await tester.tap(find.byKey(const ValueKey('search-city')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      pending.complete(http.Response('{}', 200));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
