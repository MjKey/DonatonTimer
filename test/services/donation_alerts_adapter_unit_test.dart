@Tags(['unit'])
library;

import 'package:donaton_timer/services/donation_alerts_adapter.dart';
import 'package:donaton_timer/services/donation_service_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

void main() {
  group('extractToken', () {
    test('trims a raw widget token', () {
      expect(
        DonationAlertsAdapter.extractToken('  test-widget-token  '),
        'test-widget-token',
      );
    });

    for (final domain in ['com', 'ru']) {
      test('extracts the token from a .$domain widget URL', () {
        expect(
          DonationAlertsAdapter.extractToken(
            'https://www.donationalerts.$domain/widget/alerts?group_id=1&token=test-widget-token',
          ),
          'test-widget-token',
        );
      });
    }

    test(
      'decodes the token query parameter without including other parameters',
      () {
        expect(
          DonationAlertsAdapter.extractToken(
            'https://www.donationalerts.com/widget/alerts?token=test%2Btoken%3D%26&group_id=1',
          ),
          'test+token=&',
        );
      },
    );

    for (final input in ['', '   ']) {
      test(
        'returns an empty token for ${input.isEmpty ? 'empty' : 'whitespace'} input',
        () {
          expect(DonationAlertsAdapter.extractToken(input), isEmpty);
        },
      );
    }
  });

  group('configuration validation', () {
    for (final entry in {
      'missing token': <String, dynamic>{'token': '   '},
      'unsupported domain': <String, dynamic>{
        'token': 'test-widget-token',
        'domain': 'invalid',
      },
    }.entries) {
      test('rejects ${entry.key} before making network requests', () async {
        final adapter = DonationAlertsAdapter(
          httpClient: MockClient(
            (_) async => throw StateError('Unexpected HTTP request'),
          ),
          socketConnector: (_) =>
              throw StateError('Unexpected socket connection'),
        );
        addTearDown(adapter.dispose);

        await expectLater(adapter.connect(entry.value), throwsArgumentError);

        expect(adapter.status, ConnectionStatus.error);
        expect(adapter.isConnected, isFalse);
      });
    }
  });
}
