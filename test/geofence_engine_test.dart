import 'package:flutter_portfolio/models/geofence_event.dart';
import 'package:flutter_portfolio/models/geofence_location.dart';
import 'package:flutter_portfolio/models/user_position.dart';
import 'package:flutter_portfolio/services/geofence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const spot = GeofenceLocation(
    id: 'a',
    name: 'Spot A',
    latitude: 8.0,
    longitude: 126.0,
    radiusMeters: 50,
  );

  group('GeofenceEngine.distanceMeters', () {
    test('0.001 degrees of latitude is about 111 m', () {
      final d = GeofenceEngine.distanceMeters(8.0, 126.0, 8.001, 126.0);
      expect(d, closeTo(111.2, 0.5));
    });
  });

  group('GeofenceEngine.evaluate', () {
    test('emits "entered" once when the user moves into the circle', () {
      final engine = GeofenceEngine();
      const far = UserPosition(latitude: 8.01, longitude: 126.0); // ~1.1 km away
      const near = UserPosition(latitude: 8.0001, longitude: 126.0); // ~11 m away

      expect(engine.evaluate(position: far, locations: [spot]), isEmpty);

      final events = engine.evaluate(position: near, locations: [spot]);
      expect(events.length, 1);
      expect(events.first.type, GeofenceEventType.entered);
      expect(engine.insideIds, contains('a'));

      // Staying inside produces no new event.
      expect(engine.evaluate(position: near, locations: [spot]), isEmpty);
    });

    test('emits "exited" after leaving the circle', () {
      final engine = GeofenceEngine();
      const near = UserPosition(latitude: 8.0001, longitude: 126.0);
      const far = UserPosition(latitude: 8.01, longitude: 126.0);

      engine.evaluate(position: near, locations: [spot]);
      final events = engine.evaluate(position: far, locations: [spot]);

      expect(events.length, 1);
      expect(events.first.type, GeofenceEventType.exited);
      expect(engine.insideIds, isEmpty);
    });

    test('exit buffer stops flapping right at the edge of the circle', () {
      final engine = GeofenceEngine();
      const near = UserPosition(latitude: 8.0001, longitude: 126.0);
      // ~55 m away: outside the 50 m radius but inside radius + 10 m buffer.
      const edge = UserPosition(latitude: 8.000495, longitude: 126.0);

      engine.evaluate(position: near, locations: [spot]);
      expect(engine.evaluate(position: edge, locations: [spot]), isEmpty);
      expect(engine.insideIds, contains('a'));
    });
  });
}
