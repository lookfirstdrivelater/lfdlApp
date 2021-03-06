// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lfdl_app/events.dart';
import 'package:lfdl_app/main.dart';
import 'package:latlong/latlong.dart';
import 'package:lfdl_app/utils.dart';
import 'package:lfdl_app/server.dart';
import 'dart:convert';
import 'package:lfdl_app/gps.dart';
import 'package:flutter_map/flutter_map.dart';

void main() {
  group('Road Event', () {
    final latLng1 = LatLng(0.0, 0.0);
    final latLng2 = LatLng(45.0, 90.0);
    final latLng3 = LatLng(90.0, 180.0);
    final latLngStr1 = latLngToString(latLng1);
    final latLngStr2 = latLngToString(latLng2);
    final latLngStr3 = latLngToString(latLng3);

    test('LatLng Matching', () {
      expect(latLngMatcher.hasMatch(latLngStr1), isTrue);
      expect(latLngMatcher.firstMatch(latLngStr1).group(0), latLngStr1);

      expect(latLngMatcher.hasMatch(latLngStr2), isTrue);
      expect(latLngMatcher.firstMatch(latLngStr2).group(0), latLngStr2);

      expect(latLngMatcher.hasMatch(latLngStr3), isTrue);
      expect(latLngMatcher.firstMatch(latLngStr3).group(0), latLngStr3);
    });

    test('String points to LatLng points', () {
      final String string = '"$latLngStr1, $latLngStr2, $latLngStr3"';
      final List<LatLng> transformed = stringToPoints(string);
      expect(transformed, [latLng1, latLng2, latLng3]);
    });

    test('EventType to and from strings', () {
      final eventTypes = EventType.values;
      for (int i = 0; i < eventTypes.length; i++) {
        expect(stringToEventType(eventTypeToString(eventTypes[i])), eventTypes[i]);
      }
    });

    test('Severity to and form strings', () {
      final severities = Severity.values;
      for (int i = 0; i < severities.length; i++) {
        expect(stringToSeverity(severityToString(severities[i])), severities[i]);
      }
    });

    final points = [latLng1, latLng2, latLng3];

    test('RoadEvent JSON Deserialization', () {
      final roadEvent = RoadEvent(
          id: 1,
          startTime: DateTime.utc(2019),
          endTime: DateTime.utc(2020),
          points: points,
          type: EventType.snow,
          severity: Severity.low);

      final roadEventJson = jsonDecode('''
          {
              "ID": ${roadEvent.id},
              "StartTime": "${roadEvent.startTime}",
              "EndTime": "${roadEvent.endTime}",
              "Points": "${pointsToString(roadEvent.points)}",
              "EventType": "${eventTypeToString(roadEvent.type)}",
              "Severity": "${severityToString(roadEvent.severity)}"
          }
    ''');
      expect(RoadEvent.fromJson(roadEventJson), roadEvent);
    });

    final reportEvent = ReportEvent()
        ..startTime = DateTime.utc(2019)
        ..points = points
        ..type = EventType.snow
        ..severity = Severity.low;

    test('Uploading Report Events', () async {
      final uploadedRoadEvent = await Server.uploadRoadEvent(reportEvent);
      final equal = uploadedRoadEvent == reportEvent;
      expect(equal, isTrue);
      final queriedRoadEvents1 = await Server.queryRoadEvents(reportEvent.centerY() + 0.0001, reportEvent.centerX() + 0.0001, reportEvent.centerY() - 0.0001, reportEvent.centerX() - 0.0001);
      expect(queriedRoadEvents1.contains(uploadedRoadEvent), isTrue);
      await Server.deleteRoadEvent(uploadedRoadEvent.id);
      final queriedRoadEvents2 = await Server.queryRoadEvents(reportEvent.centerY() + 0.0001, reportEvent.centerX() + 0.0001, reportEvent.centerY() - 0.0001, reportEvent.centerX() - 0.0001);
      expect(queriedRoadEvents2.contains(uploadedRoadEvent), isFalse);
    });

    test('Camel case to space case', () {
      expect(camelCaseToSpaceCase('camelCase'), 'Camel Case');
    });

    test('LatLngBounds extending', () {
      var bounds = extendBounds(LatLngBounds(LatLng(10.0, 10.0), LatLng(20.0, 20.0)));
      expect(bounds.sw, LatLng(0.0, 0.0));
      expect(bounds.ne, LatLng(30.0, 30.0));
      bounds = extendBounds(LatLngBounds(LatLng(30.0, 20.0), LatLng(40.0, 50.0)));
      expect(bounds.sw, LatLng(20.0, -10.0));
      expect(bounds.ne, LatLng(50.0, 80.0));
    });
  });
}
