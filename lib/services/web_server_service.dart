import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'log_manager.dart';

/// Сервис для управления HTTP и WebSocket серверами для интеграции с OBS.
class WebServerService extends ChangeNotifier {
  HttpServer? _httpServer;
  HttpServer? _wsServer;
  final List<WebSocketChannel> _clients = [];
  
  int _httpPort;
  int _wsPort;
  String _localIpAddress = 'localhost';
  
  bool _isHttpRunning = false;
  bool _isWsRunning = false;
  
  // Callbacks for handling WebSocket commands
  Function()? onStartTimer;
  Function()? onStopTimer;
  Function(int seconds)? onChangeTime;
  
  // Current timer state for broadcasting
  int _currentDuration = 0;
  List<Map<String, dynamic>> _recentDonations = [];
  Map<String, int> _topDonators = {};
  
  WebServerService({
    int httpPort = 8080,
    int wsPort = 4040,
  }) : _httpPort = httpPort,
       _wsPort = wsPort;
  
  int get httpPort => _httpPort;
  int get wsPort => _wsPort;
  String get localIpAddress => _localIpAddress;
  bool get isHttpRunning => _isHttpRunning;
  bool get isWsRunning => _isWsRunning;
  int get clientCount => _clients.length;
  
  /// Инициализирует сервис и запускает оба сервера.
  Future<void> init() async {
    await _getLocalIpAddress();
    await startHttpServer(_httpPort);
    await startWebSocketServer(_wsPort);
  }
  
  /// Получает локальный IP адрес.
  Future<void> _getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      final ipAddress = await info.getWifiIP();
      _localIpAddress = ipAddress ?? 'localhost';
      debugPrint('WebServerService: Local IP: $_localIpAddress');
    } catch (e) {
      _localIpAddress = 'localhost';
      debugPrint('WebServerService: Failed to get IP, using localhost: $e');
    }
  }
  
  /// Запускает HTTP сервер на указанном порту.
  Future<void> startHttpServer(int port) async {
    try {
      await stopHttpServer();
      
      final router = Router();
      
      // Timer page for OBS Browser Source
      router.get('/timer', _handleTimerPage);
      
      // Dashboard for mobile/browser control
      router.get('/dashboard', _handleDashboardPage);
      
      // Mini version for OBS dock panel
      router.get('/mini', _handleMiniPage);
      
      // Root redirects to dashboard
      router.get('/', (Request request) {
        return Response.found('/dashboard');
      });
      
      final handler = const Pipeline()
          .addMiddleware(_corsMiddleware())
          .addHandler(router.call);
      
      _httpServer = await shelf_io.serve(handler, '0.0.0.0', port);
      _httpPort = port;
      _isHttpRunning = true;
      
      LogManager.info('HTTP сервер запущен на порту $port');
      notifyListeners();
    } catch (e) {
      LogManager.error('Ошибка запуска HTTP сервера: $e');
      _isHttpRunning = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Запускает WebSocket сервер на указанном порту.
  Future<void> startWebSocketServer(int port) async {
    try {
      await stopWebSocketServer();
      
      _wsServer = await HttpServer.bind('0.0.0.0', port);
      _wsPort = port;
      _isWsRunning = true;
      
      LogManager.info('WebSocket сервер запущен на порту $port');
      notifyListeners();
      
      _wsServer!.listen((HttpRequest request) {
        if (request.uri.path == '/' || request.uri.path.isEmpty) {
          WebSocketTransformer.upgrade(request).then((WebSocket socket) {
            final channel = IOWebSocketChannel(socket);
            _clients.add(channel);
            notifyListeners();
            
            // Send current state to new client
            _sendCurrentState(channel);
            
            // Listen for messages from client
            channel.stream.listen(
              (message) => _handleWebSocketMessage(message),
              onDone: () {
                _clients.remove(channel);
                notifyListeners();
              },
              onError: (error) {
                debugPrint('WebServerService: WebSocket error: $error');
                _clients.remove(channel);
                notifyListeners();
              },
            );
          }).catchError((error) {
            debugPrint('WebServerService: WebSocket upgrade failed: $error');
          });
        }
      });
    } catch (e) {
      LogManager.error('Ошибка запуска WebSocket сервера: $e');
      _isWsRunning = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Останавливает HTTP сервер.
  Future<void> stopHttpServer() async {
    if (_httpServer != null) {
      await _httpServer!.close();
      _httpServer = null;
      _isHttpRunning = false;
      debugPrint('WebServerService: HTTP server stopped');
      notifyListeners();
    }
  }
  
  /// Останавливает WebSocket сервер.
  Future<void> stopWebSocketServer() async {
    // Close all client connections
    final clientsToClose = List.of(_clients);
    for (final client in clientsToClose) {
      try {
        await client.sink.close();
      } catch (e) {
        debugPrint('WebServerService: Error closing client: $e');
      }
    }
    _clients.clear();
    
    if (_wsServer != null) {
      await _wsServer!.close();
      _wsServer = null;
      _isWsRunning = false;
      debugPrint('WebServerService: WebSocket server stopped');
      notifyListeners();
    }
  }
  
  /// Перезапускает оба сервера с новыми портами.
  Future<void> restartServers({int? httpPort, int? wsPort}) async {
    await stopHttpServer();
    await stopWebSocketServer();
    await startHttpServer(httpPort ?? _httpPort);
    await startWebSocketServer(wsPort ?? _wsPort);
  }
  
  /// Обновляет длительность таймера и отправляет всем клиентам.
  void updateTimerDuration(int duration) {
    _currentDuration = duration;
    broadcast({
      'action': 'update_timer',
      'duration': duration,
    });
  }
  
  /// Обновляет статистику донатов и отправляет всем клиентам.
  void updateDonations({
    List<Map<String, dynamic>>? recentDonations,
    Map<String, int>? topDonators,
  }) {
    if (recentDonations != null) {
      _recentDonations = recentDonations;
    }
    if (topDonators != null) {
      _topDonators = topDonators;
    }
    broadcast({
      'action': 'update_donations',
      'recentDonations': _recentDonations,
      'topDonators': _topDonators,
    });
  }
  
  /// Отправляет сообщение всем подключённым клиентам.
  void broadcast(Map<String, dynamic> message) {
    final jsonMessage = json.encode(message);
    for (final client in _clients) {
      try {
        client.sink.add(jsonMessage);
      } catch (e) {
        debugPrint('WebServerService: Error broadcasting to client: $e');
      }
    }
  }
  
  /// Отправляет текущее состояние клиенту.
  void _sendCurrentState(WebSocketChannel client) {
    try {
      client.sink.add(json.encode({
        'action': 'update_timer',
        'duration': _currentDuration,
      }));
      client.sink.add(json.encode({
        'action': 'update_donations',
        'recentDonations': _recentDonations,
        'topDonators': _topDonators,
      }));
    } catch (e) {
      debugPrint('WebServerService: Error sending state to client: $e');
    }
  }
  
  /// Обрабатывает входящие WebSocket сообщения.
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      debugPrint('WebServerService: Received message: $data');
      
      switch (data['action']) {
        case 'start':
          onStartTimer?.call();
          break;
        case 'stop':
          onStopTimer?.call();
          break;
        case 'change_time':
          final seconds = data['seconds'] as int?;
          if (seconds != null) {
            onChangeTime?.call(seconds);
          }
          break;
      }
    } catch (e) {
      debugPrint('WebServerService: Error handling message: $e');
    }
  }
  
  /// CORS middleware для кросс-доменных запросов.
  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        });
      };
    };
  }

  /// Обрабатывает запрос страницы /timer для OBS Browser Source.
  Response _handleTimerPage(Request request) {
    final htmlContent = '''
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Донатон Таймер</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@400;700&display=swap" rel="stylesheet">
    <style id="dynamic-css">
      body {
        margin: 0;
        padding: 0;
        background-color: transparent;
      }
      #timer-container {
        display: flex;
        justify-content: center;
        align-items: center;
        width: 400px;
        height: 100px;
        padding: 10px 20px;
        box-sizing: border-box;
        margin: 0 auto;
        background-color: #000000;
      }
      #timer {
        display: flex;
        justify-content: center;
        align-items: center;
        font-family: "Roboto Mono", monospace;
        font-size: 72px;
        color: #FFFFFF;
        font-weight: bold;
        letter-spacing: 2px;
        text-shadow: 2px 2px 4px #000000;
      }
      .digit { }
      .separator { }
      #hours { }
      #minutes { }
      #seconds { }
      #sep1 { }
      #sep2 { }
    </style>
</head>
<body>
    <div id="timer-container">
      <div id="timer">
        <span id="hours" class="digit">00</span><span id="sep1" class="separator">:</span><span id="minutes" class="digit">00</span><span id="sep2" class="separator">:</span><span id="seconds" class="digit">00</span>
      </div>
    </div>
    <script>
      let reconnectAttempts = 0;
      const maxReconnectAttempts = 10;
      const reconnectDelay = 2000;
      
      function connect() {
        const socket = new WebSocket('ws://$_localIpAddress:$_wsPort');
        
        socket.onopen = function() {
          console.log('WebSocket connected');
          reconnectAttempts = 0;
        };
        
        socket.onmessage = function(event) {
          const data = JSON.parse(event.data);
          if (data.action === 'update_timer') {
            const duration = data.duration;
            let hours = Math.floor(duration / 3600);
            let minutes = Math.floor((duration % 3600) / 60);
            let seconds = duration % 60;
            document.getElementById('hours').innerText = hours.toString().padStart(2, '0');
            document.getElementById('minutes').innerText = minutes.toString().padStart(2, '0');
            document.getElementById('seconds').innerText = seconds.toString().padStart(2, '0');
          }
        };
        
        socket.onclose = function() {
          console.log('WebSocket disconnected');
          if (reconnectAttempts < maxReconnectAttempts) {
            reconnectAttempts++;
            setTimeout(connect, reconnectDelay);
          }
        };
        
        socket.onerror = function(error) {
          console.error('WebSocket error:', error);
        };
      }
      
      connect();
    </script>
</body>
</html>
''';
    return Response.ok(htmlContent, headers: {'Content-Type': 'text/html; charset=utf-8'});
  }
  
  /// Обрабатывает запрос страницы /dashboard для мобильного управления.
  Response _handleDashboardPage(Request request) {
    final htmlContent = '''
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Донатон Таймер - Панель управления</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
    <style>
        .hero.is-fullheight {
            min-height: 100vh;
        }
        #timer {
            font-size: 4rem;
            font-weight: bold;
            font-family: monospace;
        }
        .donation-list {
            max-height: 300px;
            overflow-y: auto;
        }
        .connection-status {
            position: fixed;
            top: 10px;
            right: 10px;
            padding: 5px 10px;
            border-radius: 5px;
            font-size: 0.8rem;
        }
        .connected { background-color: #48c774; color: white; }
        .disconnected { background-color: #f14668; color: white; }
    </style>
</head>
<body>
    <div id="connection-status" class="connection-status disconnected">Отключено</div>
    <section class="hero is-fullheight is-light">
        <div class="hero-body">
            <div class="container">
                <h1 class="title has-text-centered is-size-2 mb-6">
                    🎮 Донатон Таймер
                </h1>
                <div class="columns is-centered">
                    <div class="column is-narrow">
                        <div class="box">
                            <div id="timer" class="has-text-centered mb-4">00:00:00</div>
                            <div class="buttons are-medium is-centered">
                                <button class="button is-primary" id="startStopBtn" onclick="startStop()">
                                    <span class="icon">
                                        <i class="fa fa-play" id="playIcon"></i>
                                    </span>
                                    <span id="startStopText">Старт</span>
                                </button>
                            </div>
                            <div class="buttons are-medium is-centered">
                                <button class="button is-danger" onclick="changeTime(-60)">
                                    <span class="icon">
                                        <i class="fa fa-minus"></i>
                                    </span>
                                    <span>1 мин</span>
                                </button>
                                <button class="button is-success" onclick="changeTime(60)">
                                    <span class="icon">
                                        <i class="fa fa-plus"></i>
                                    </span>
                                    <span>1 мин</span>
                                </button>
                            </div>
                            <div class="field has-addons has-addons-centered mt-4">
                                <div class="control">
                                    <input class="input" type="number" id="minutesInput" placeholder="±Минуты">
                                </div>
                                <div class="control">
                                    <button class="button is-info" onclick="addCustomTime()">
                                        Добавить/Отнять
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="columns mt-6">
                    <div class="column">
                        <div class="box">
                            <h2 class="title is-4 has-text-centered">📋 Последние донаты</h2>
                            <div class="donation-list">
                                <ul id="recentDonationsList" class="content"></ul>
                            </div>
                        </div>
                    </div>
                    <div class="column">
                        <div class="box">
                            <h2 class="title is-4 has-text-centered">🏆 Топ донатеров</h2>
                            <div class="donation-list">
                                <ul id="topDonatorsList" class="content"></ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
    <footer class="footer">
        <div class="content has-text-centered">
            <p>Dev. MjKey | <a href="http://$_localIpAddress:$_httpPort/mini">Мини-версия</a></p>
        </div>
    </footer>

    <script>
        let socket;
        let isRunning = false;
        let reconnectAttempts = 0;
        const maxReconnectAttempts = 10;
        const reconnectDelay = 2000;
        
        function connect() {
            socket = new WebSocket('ws://$_localIpAddress:$_wsPort');
            
            socket.onopen = function() {
                console.log('WebSocket connected');
                reconnectAttempts = 0;
                updateConnectionStatus(true);
            };

            socket.onmessage = function(event) {
                const data = JSON.parse(event.data);
                if (data.action === 'update_timer') {
                    updateTimer(data.duration);
                } else if (data.action === 'update_donations') {
                    updateDonations(data.recentDonations, data.topDonators);
                }
            };
            
            socket.onclose = function() {
                console.log('WebSocket disconnected');
                updateConnectionStatus(false);
                if (reconnectAttempts < maxReconnectAttempts) {
                    reconnectAttempts++;
                    setTimeout(connect, reconnectDelay);
                }
            };
            
            socket.onerror = function(error) {
                console.error('WebSocket error:', error);
            };
        }
        
        function updateConnectionStatus(connected) {
            const status = document.getElementById('connection-status');
            if (connected) {
                status.textContent = 'Подключено';
                status.className = 'connection-status connected';
            } else {
                status.textContent = 'Отключено';
                status.className = 'connection-status disconnected';
            }
        }

        function updateTimer(duration) {
            let hours = Math.floor(duration / 3600);
            let minutes = Math.floor((duration % 3600) / 60);
            let seconds = duration % 60;
            document.getElementById('timer').innerText = 
                [hours, minutes, seconds].map(num => num.toString().padStart(2, '0')).join(':');
        }

        function startStop() {
            isRunning = !isRunning;
            socket.send(JSON.stringify({action: isRunning ? 'start' : 'stop'}));
            updateStartStopButton();
        }
        
        function updateStartStopButton() {
            const icon = document.getElementById('playIcon');
            const text = document.getElementById('startStopText');
            if (isRunning) {
                icon.className = 'fa fa-pause';
                text.textContent = 'Пауза';
            } else {
                icon.className = 'fa fa-play';
                text.textContent = 'Старт';
            }
        }

        function changeTime(seconds) {
            socket.send(JSON.stringify({action: 'change_time', seconds: seconds}));
        }

        function addCustomTime() {
            const minutes = document.getElementById('minutesInput').value;
            if (minutes) {
                changeTime(parseInt(minutes) * 60);
                document.getElementById('minutesInput').value = '';
            }
        }

        function updateDonations(recentDonations, topDonators) {
            const recentList = document.getElementById('recentDonationsList');
            const topList = document.getElementById('topDonatorsList');
            
            if (recentDonations && recentDonations.length > 0) {
                recentList.innerHTML = recentDonations.map(d => 
                    `<li>\${d.username}: +\${d.minutesAdded} мин</li>`
                ).join('');
            } else {
                recentList.innerHTML = '<li class="has-text-grey">Пока нет донатов</li>';
            }
            
            if (topDonators && Object.keys(topDonators).length > 0) {
                topList.innerHTML = Object.entries(topDonators)
                    .map(([name, minutes], index) => 
                        `<li>\${index + 1}. \${name}: \${minutes} мин</li>`
                    ).join('');
            } else {
                topList.innerHTML = '<li class="has-text-grey">Пока нет донатеров</li>';
            }
        }
        
        // Handle Enter key in input
        document.getElementById('minutesInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                addCustomTime();
            }
        });
        
        connect();
    </script>
</body>
</html>
''';
    return Response.ok(htmlContent, headers: {'Content-Type': 'text/html; charset=utf-8'});
  }

  /// Обрабатывает запрос страницы /mini для OBS dock панели.
  Response _handleMiniPage(Request request) {
    final htmlContent = '''
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Донатон Таймер - Мини</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
    <style>
        body {
            margin: 0;
            padding: 10px;
            min-height: auto;
        }
        .hero-body {
            padding: 0;
        }
        #timer {
            font-size: 2.5rem;
            font-weight: bold;
            font-family: monospace;
        }
        .box {
            padding: 15px;
            margin: 0;
        }
        .buttons:not(:last-child) {
            margin-bottom: 0.5rem;
        }
        .field {
            margin-bottom: 0;
        }
    </style>
</head>
<body class="is-light">
    <div class="box">
        <div id="timer" class="has-text-centered mb-3">00:00:00</div>
        <div class="buttons are-small is-centered">
            <button class="button is-primary" id="startStopBtn" onclick="startStop()">
                <span class="icon">
                    <i class="fa fa-play" id="playIcon"></i>
                </span>
                <span id="startStopText">Старт</span>
            </button>
        </div>
        <div class="buttons are-small is-centered">
            <button class="button is-danger" onclick="changeTime(-60)">
                <span class="icon"><i class="fa fa-minus"></i></span>
                <span>1м</span>
            </button>
            <button class="button is-success" onclick="changeTime(60)">
                <span class="icon"><i class="fa fa-plus"></i></span>
                <span>1м</span>
            </button>
        </div>
        <div class="field has-addons has-addons-centered">
            <div class="control">
                <input class="input is-small" type="number" id="minutesInput" placeholder="±мин" style="width: 80px;">
            </div>
            <div class="control">
                <button class="button is-info is-small" onclick="addCustomTime()">OK</button>
            </div>
        </div>
    </div>

    <script>
        let socket;
        let isRunning = false;
        let reconnectAttempts = 0;
        const maxReconnectAttempts = 10;
        const reconnectDelay = 2000;
        
        function connect() {
            socket = new WebSocket('ws://$_localIpAddress:$_wsPort');
            
            socket.onopen = function() {
                console.log('WebSocket connected');
                reconnectAttempts = 0;
            };

            socket.onmessage = function(event) {
                const data = JSON.parse(event.data);
                if (data.action === 'update_timer') {
                    updateTimer(data.duration);
                }
            };
            
            socket.onclose = function() {
                console.log('WebSocket disconnected');
                if (reconnectAttempts < maxReconnectAttempts) {
                    reconnectAttempts++;
                    setTimeout(connect, reconnectDelay);
                }
            };
            
            socket.onerror = function(error) {
                console.error('WebSocket error:', error);
            };
        }

        function updateTimer(duration) {
            let hours = Math.floor(duration / 3600);
            let minutes = Math.floor((duration % 3600) / 60);
            let seconds = duration % 60;
            document.getElementById('timer').innerText = 
                [hours, minutes, seconds].map(num => num.toString().padStart(2, '0')).join(':');
        }

        function startStop() {
            isRunning = !isRunning;
            socket.send(JSON.stringify({action: isRunning ? 'start' : 'stop'}));
            updateStartStopButton();
        }
        
        function updateStartStopButton() {
            const icon = document.getElementById('playIcon');
            const text = document.getElementById('startStopText');
            if (isRunning) {
                icon.className = 'fa fa-pause';
                text.textContent = 'Пауза';
            } else {
                icon.className = 'fa fa-play';
                text.textContent = 'Старт';
            }
        }

        function changeTime(seconds) {
            socket.send(JSON.stringify({action: 'change_time', seconds: seconds}));
        }

        function addCustomTime() {
            const minutes = document.getElementById('minutesInput').value;
            if (minutes) {
                changeTime(parseInt(minutes) * 60);
                document.getElementById('minutesInput').value = '';
            }
        }
        
        document.getElementById('minutesInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                addCustomTime();
            }
        });
        
        connect();
    </script>
</body>
</html>
''';
    return Response.ok(htmlContent, headers: {'Content-Type': 'text/html; charset=utf-8'});
  }
  
  /// Возвращает URL страницы таймера для OBS.
  String getTimerUrl() => 'http://$_localIpAddress:$_httpPort/timer';
  
  /// Возвращает URL панели управления.
  String getDashboardUrl() => 'http://$_localIpAddress:$_httpPort/dashboard';
  
  /// Возвращает URL мини-страницы для OBS dock.
  String getMiniUrl() => 'http://$_localIpAddress:$_httpPort/mini';
  
  /// Освобождает все ресурсы.
  @override
  void dispose() {
    stopHttpServer();
    stopWebSocketServer();
    super.dispose();
  }
}
