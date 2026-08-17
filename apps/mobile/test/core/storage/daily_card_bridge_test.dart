import 'package:flutter_test/flutter_test.dart';
import 'package:security_pulse/core/storage/daily_card_bridge.dart';

void main() {
  group('DailyCardBridgeModel', () {
    test('toJson produces correct keys for available state', () {
      const model = DailyCardBridgeModel(
        title: 'Phishing Quiz',
        completionState: 'available',
        scenarioId: 'abc-123',
        deepLinkRoute: '/today',
        expiresAt: '2026-08-16T12:00:00.000Z',
      );
      final json = model.toJson();

      expect(json['scenarioId'], 'abc-123');
      expect(json['title'], 'Phishing Quiz');
      expect(json['completionState'], 'available');
      expect(json['deepLinkRoute'], '/today');
      expect(json['expiresAt'], '2026-08-16T12:00:00.000Z');
    });

    test('toJson produces correct keys for completed state', () {
      const model = DailyCardBridgeModel(
        title: 'Password Security',
        completionState: 'completed',
        scenarioId: 'def-456',
        deepLinkRoute: '/progress',
        expiresAt: '2026-08-16T14:00:00.000Z',
      );
      final json = model.toJson();

      expect(json['completionState'], 'completed');
      expect(json['deepLinkRoute'], '/progress');
    });

    test('toJson serializes null fields as empty strings', () {
      const model = DailyCardBridgeModel(
        title: 'Security Pulse',
        completionState: 'no_assignment',
      );
      final json = model.toJson();

      expect(json['scenarioId'], '');
      expect(json['deepLinkRoute'], '');
      expect(json['expiresAt'], '');
    });

    test('toJson produces all five completion states correctly', () {
      for (final state in [
        'available',
        'completed',
        'no_assignment',
        'offline',
        'signed_out',
      ]) {
        final model = DailyCardBridgeModel(
          title: 'Test',
          completionState: state,
        );
        expect(model.toJson()['completionState'], state);
      }
    });

    test('JSON keys match Android DailyCardModel.kt schema', () {
      const model = DailyCardBridgeModel(
        title: 'Test',
        completionState: 'available',
      );
      final json = model.toJson();

      // These exact keys are read by DailyCardModel.kt via JSONObject
      expect(json.containsKey('scenarioId'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('completionState'), isTrue);
      expect(json.containsKey('deepLinkRoute'), isTrue);
      expect(json.containsKey('expiresAt'), isTrue);
      expect(json.length, 5);
    });
  });

  group('NoOpWidgetBridge', () {
    test('records updateWidget calls', () async {
      final bridge = NoOpWidgetBridge();
      const model = DailyCardBridgeModel(
        title: 'Test',
        completionState: 'available',
      );

      await bridge.updateWidget(model);
      await bridge.updateWidget(model);

      expect(bridge.updates, hasLength(2));
      expect(bridge.updates.first.completionState, 'available');
    });

    test('records clearWidget calls', () async {
      final bridge = NoOpWidgetBridge();

      await bridge.clearWidget();
      await bridge.clearWidget();
      await bridge.clearWidget();

      expect(bridge.clearCount, 3);
    });
  });
}
