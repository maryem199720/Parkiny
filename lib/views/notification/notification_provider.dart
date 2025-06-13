import 'dart:convert';
import 'package:flutter/material.dart' as material;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_parking/models/notification.dart';

class NotificationProviderImproved with material.ChangeNotifier {
  List<ParkingNotification> _notifications = [];
  bool _isConnected = false;
  WebSocketChannel? _channel;
  String? _userId;
  String? _token;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<ParkingNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isConnected => _isConnected;

  Future<void> init() async {
    _token = await _storage.read(key: 'auth_token');
    _userId = await _storage.read(key: 'user_id');

    if (_token == null || _userId == null) {
      print('Missing token or userId');
      return;
    }

    await fetchNotifications();
    connectWebSocket();
  }

  void connectWebSocket() {
    if (_channel != null) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://10.0.2.2:8082/parking/ws'),
        protocols: ['v10.stomp', 'v11.stomp'],
      );

      _isConnected = true;
      notifyListeners();

      // Send STOMP CONNECT frame with JWT
      _channel!.sink.add(
        'CONNECT\naccept-version:1.1,1.0\nhost:10.0.2.2:8082\nAuthorization:Bearer $_token\n\n\x00',
      );

      _channel!.stream.listen(
            (message) {
          print('WebSocket message received: $message');

          if (message.contains('CONNECTED')) {
            print('WebSocket connected successfully');
            // Subscribe to user-specific notifications after connection
            _channel!.sink.add(
              'SUBSCRIBE\nid:sub-0\ndestination:/user/$_userId/topic/notifications\n\n\x00',
            );
          } else if (message.contains('MESSAGE')) {
            try {
              final lines = message.split('\n');
              final bodyIndex = lines.indexWhere((line) => line.isEmpty);
              if (bodyIndex != -1 && bodyIndex + 1 < lines.length) {
                final body = lines.sublist(bodyIndex + 1).join('\n').trim();
                if (body.isNotEmpty && body != '\x00') {
                  final cleanBody = body.replaceAll('\x00', '');
                  final data = jsonDecode(cleanBody);
                  final notification = ParkingNotification.fromJson(data);
                  _notifications.insert(0, notification);
                  notifyListeners();
                  print('Notification added: ${notification.message}');
                }
              }
            } catch (e) {
              print('Error parsing notification: $e');
            }
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
          _channel = null;
          Future.delayed(const Duration(seconds: 5), connectWebSocket);
        },
        onDone: () {
          print('WebSocket closed');
          _isConnected = false;
          notifyListeners();
          _channel = null;
          Future.delayed(const Duration(seconds: 5), connectWebSocket);
        },
      );
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;
      notifyListeners();
      Future.delayed(const Duration(seconds: 5), connectWebSocket);
    }
  }

  Future<void> fetchNotifications() async {
    if (_token == null || _userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/notifications/my'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((json) => ParkingNotification.fromJson(json)).toList();
        notifyListeners();
      } else {
        print('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> markAsRead(int id) async {
    if (_token == null || _userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/parking/api/notifications/my/$id/read'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index].isRead = true;
          notifyListeners();
        }
      } else {
        print('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void disposeWebSocket() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  @override
  void dispose() {
    disposeWebSocket();
    super.dispose();
  }
}