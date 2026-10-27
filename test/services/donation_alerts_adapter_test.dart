@Tags(['component'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:donaton_timer/models/donation.dart';
import 'package:donaton_timer/services/donation_alerts_adapter.dart';
import 'package:donaton_timer/services/donation_service_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _donationChannel = r'$alerts:donation_8887508';
const _donationData = {
  'id': 193203471,
  'name': 'Donations',
  'username': 'TestUser',
  'message': '',
  'message_type': 'text',
  'amount': 300,
  'currency': 'RUB',
  'is_shown': 0,
  'reason': 'default',
};

String _publication({
  String channel = _donationChannel,
  Map<String, dynamic> data = _donationData,
  int? type,
}) => jsonEncode({
  'result': {
    'channel': channel,
    'type': ?type,
    'data': {'seq': 14, 'data': data},
  },
});

void main() {
  late HttpServer server;
  late DonationAlertsAdapter adapter;
  late WebSocket socket;
  late List<http.Request> requests;
  late List<Map<String, dynamic>> commands;
  late Completer<void> subscribeRequested;
  late Completer<void> pingRequested;
  int? sessionTtl;
  bool holdSubscription = false;
  bool rejectSubscription = false;
  Map<String, dynamic>? pendingSubscribe;
  var connections = 0;

  void reply(Map<String, dynamic> command, Map<String, dynamic> result) {
    socket.add(jsonEncode({'id': command['id'], 'result': result}));
  }

  setUp(() async {
    requests = [];
    commands = [];
    subscribeRequested = Completer<void>();
    pingRequested = Completer<void>();
    sessionTtl = null;
    holdSubscription = false;
    rejectSubscription = false;
    pendingSubscribe = null;
    connections = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      socket = await WebSocketTransformer.upgrade(request);
      connections++;
      socket.listen((raw) {
        final command = jsonDecode(raw as String) as Map<String, dynamic>;
        commands.add(command);
        if (command['method'] == 1) {
          pendingSubscribe = command;
          if (!subscribeRequested.isCompleted) subscribeRequested.complete();
          if (rejectSubscription) {
            socket.add(
              jsonEncode({
                'id': command['id'],
                'error': {'code': 103, 'message': 'permission denied'},
              }),
            );
          } else if (!holdSubscription) {
            reply(command, {'recoverable': false});
          }
        } else if (command['method'] == 7) {
          if (!pingRequested.isCompleted) pingRequested.complete();
          socket.add(jsonEncode({'id': command['id']}));
        } else {
          reply(command, {
            'client': 'test-client',
            'version': '2.8.5',
            if (sessionTtl != null) 'expires': true,
            'ttl': ?sessionTtl,
          });
        }
      });
    });
    adapter = DonationAlertsAdapter(
      httpClient: MockClient((request) async {
        requests.add(request);
        Object response;
        switch (request.url.path) {
          case '/api/v1/token/widget':
            expect(request.url.queryParameters['token'], 'widget-secret');
            response = {
              'data': {'token': 'api-secret'},
            };
          case '/api/v1/user/widget':
            expect(request.headers['Authorization'], 'Bearer api-secret');
            response = {
              'data': {
                'id': 8887508,
                'socket_connection_token': 'connection-secret',
              },
            };
          case '/api/v1/centrifuge/subscribe':
            expect(request.method, 'POST');
            expect(request.headers['Authorization'], 'Bearer api-secret');
            expect(jsonDecode(request.body), {
              'client': 'test-client',
              'channels': [_donationChannel],
            });
            response = {
              'channels': [
                {'channel': _donationChannel, 'token': 'subscription-secret'},
              ],
            };
          default:
            throw StateError('Unexpected API request');
        }
        return http.Response(jsonEncode(response), 200);
      }),
      socketConnector: (uri) {
        expect(
          uri.toString(),
          'wss://centrifugo.donationalerts.com/connection/websocket',
        );
        return WebSocketChannel.connect(
          Uri.parse('ws://127.0.0.1:${server.port}'),
        );
      },
    );
  });

  tearDown(() async {
    await adapter.dispose();
    await server.close(force: true);
  });

  test(
    'receives the supplied Centrifugo donation with saved legacy settings',
    () async {
      await adapter.connect({
        'token':
            'https://www.donationalerts.com/widget/alerts?group_id=1&token=widget-secret',
        'socketServer': 'socket4',
        'domain': 'com',
      });
      expect(adapter.isConnected, isTrue);
      expect(commands.first['params'], {'token': 'connection-secret'});
      expect(commands.last['params'], {
        'channel': _donationChannel,
        'token': 'subscription-secret',
      });
      final received = adapter.donationStream.first;
      socket.add(_publication());
      final donation = await received.timeout(const Duration(seconds: 2));
      expect(donation.id, 'DonationAlerts_193203471');
      expect(donation.username, 'TestUser');
      expect(donation.amount, 300);
      expect(donation.currency, 'RUB');
      expect(donation.message, '');
    },
  );

  test(
    'waits for subscription confirmation before reporting connected',
    () async {
      holdSubscription = true;
      final connecting = adapter.connect({'token': 'widget-secret'});
      await subscribeRequested.future.timeout(const Duration(seconds: 2));
      expect(adapter.status, ConnectionStatus.connecting);
      expect(adapter.isConnected, isFalse);
      reply(pendingSubscribe!, {});
      await connecting;
      expect(adapter.isConnected, isTrue);
    },
  );

  test(
    'subscription rejection never reports a successful connection',
    () async {
      rejectSubscription = true;
      final statuses = <ConnectionStatus>[];
      final subscription = adapter.statusStream.listen(statuses.add);
      await expectLater(
        adapter.connect({'token': 'widget-secret'}),
        throwsStateError,
      );
      expect(adapter.isConnected, isFalse);
      expect(adapter.status, ConnectionStatus.reconnecting);
      expect(statuses, isNot(contains(ConnectionStatus.connected)));
      await subscription.cancel();
    },
  );

  test(
    'ignores unrelated and shown alerts and continues after malformed JSON',
    () async {
      await adapter.connect({'token': 'widget-secret'});
      final donations = <Donation>[];
      final subscription = adapter.donationStream.listen(donations.add);
      final received = adapter.donationStream.first;
      socket.add(
        [
          'invalid JSON',
          _publication(channel: r'$alerts:donation_123'),
          _publication(type: 1),
          _publication(data: {..._donationData, 'is_shown': 1}),
          _publication(data: {..._donationData, 'amount': 'NaN'}),
          _publication(data: {..._donationData, 'amount': '300.50'}),
        ].join('\n'),
      );
      expect(
        (await received.timeout(const Duration(seconds: 2))).amount,
        300.5,
      );
      expect(donations, hasLength(1));
      await subscription.cancel();
    },
  );

  test('reconnects and authorizes again after a closed socket', () async {
    await adapter.connect({'token': 'widget-secret'});
    final reconnected = adapter.statusStream.firstWhere(
      (status) => status == ConnectionStatus.connected,
    );
    await socket.close();
    await reconnected.timeout(const Duration(seconds: 9));
    expect(connections, 2);
    expect(
      requests.where((request) => request.url.path == '/api/v1/token/widget'),
      hasLength(2),
    );
    final received = adapter.donationStream.first;
    socket.add(_publication());
    expect((await received.timeout(const Duration(seconds: 2))).amount, 300);
  });

  test(
    'disconnect cancels a pending subscription and does not reconnect',
    () async {
      holdSubscription = true;
      final failedConnection = expectLater(
        adapter.connect({'token': 'widget-secret'}),
        throwsStateError,
      );
      await subscribeRequested.future.timeout(const Duration(seconds: 2));
      await adapter.disconnect();
      await failedConnection;
      expect(adapter.status, ConnectionStatus.disconnected);
      await Future<void>.delayed(const Duration(seconds: 6));
      expect(connections, 1);
    },
  );

  test('sends Centrifugo ping and keeps the subscription active', () async {
    await adapter.connect({'token': 'widget-secret'});
    await pingRequested.future.timeout(const Duration(seconds: 28));
    expect(commands.last['method'], 7);
    expect(adapter.isConnected, isTrue);
  }, timeout: const Timeout(Duration(seconds: 35)));

  test('renews expiring authorization by opening a fresh session', () async {
    sessionTtl = 2;
    await adapter.connect({'token': 'widget-secret'});
    final renewed = adapter.statusStream.firstWhere(
      (status) => status == ConnectionStatus.connected,
    );
    await renewed.timeout(const Duration(seconds: 9));
    expect(connections, 2);
    expect(
      requests.where((request) => request.url.path == '/api/v1/token/widget'),
      hasLength(2),
    );
  });

  test('only the latest of concurrent connect calls opens a socket', () async {
    final cancelled = expectLater(
      adapter.connect({'token': 'widget-secret'}),
      throwsStateError,
    );
    await adapter.connect({'token': 'widget-secret'});
    await cancelled;
    expect(connections, 1);
    expect(adapter.isConnected, isTrue);
  });

  test('a subscribe response without result never reports connected', () async {
    holdSubscription = true;
    final rejected = expectLater(
      adapter.connect({'token': 'widget-secret'}),
      throwsStateError,
    );
    await subscribeRequested.future.timeout(const Duration(seconds: 2));
    socket.add(jsonEncode({'id': pendingSubscribe!['id']}));
    await rejected;
    expect(adapter.isConnected, isFalse);
  });

  for (final status in [202, 401, 403]) {
    test(
      'invalid widget token with HTTP $status stops automatic retries',
      () async {
        await adapter.dispose();
        adapter = DonationAlertsAdapter(
          httpClient: MockClient(
            (request) async => http.Response(
              '{"success":false,"code":1001,"message":"Invalid token passed"}',
              status,
            ),
          ),
        );
        await expectLater(
          adapter.connect({'token': 'widget-secret'}),
          throwsA(
            predicate(
              (error) => error.toString().contains('актуальный токен виджета'),
            ),
          ),
        );
        expect(adapter.status, ConnectionStatus.error);
        expect(connections, 0);
      },
    );
  }

  test(
    'disconnect during token loading prevents a late socket connection',
    () async {
      await adapter.dispose();
      final response = Completer<http.Response>();
      final requested = Completer<void>();
      var opened = false;
      adapter = DonationAlertsAdapter(
        httpClient: MockClient((_) {
          requested.complete();
          return response.future;
        }),
        socketConnector: (_) {
          opened = true;
          throw StateError('Should not connect');
        },
      );
      final cancelled = expectLater(
        adapter.connect({'token': 'widget-secret'}),
        throwsStateError,
      );
      await requested.future;
      await adapter.disconnect();
      response.complete(http.Response('{"data":{"token":"api-secret"}}', 200));
      await cancelled;
      expect(opened, isFalse);
      expect(adapter.status, ConnectionStatus.disconnected);
    },
  );
}
