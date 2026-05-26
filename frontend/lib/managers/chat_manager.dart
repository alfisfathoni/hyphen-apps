import 'package:flutter/foundation.dart';
import 'package:hyphen/services/api_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hyphen/managers/auth_manager.dart';
import 'package:dio/dio.dart';

class ChatManager extends ChangeNotifier {
  // Singleton pattern
  static final ChatManager _instance = ChatManager._internal();
  factory ChatManager() => _instance;
  ChatManager._internal();

  IO.Socket? socket;
  String? activeRoomId;

  List<dynamic> _rooms = [];
  List<dynamic> get rooms => _rooms;

  List<dynamic> _messages = [];
  List<dynamic> get messages => _messages;

  bool _isLoadingRooms = false;
  bool get isLoadingRooms => _isLoadingRooms;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  void initSocket() {
    if (socket != null && socket!.connected) return;

    final socketUrl = ApiClient.baseUrl.replaceAll('/api/v1', '');
    print(' Connecting to socket at: $socketUrl');

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      print(' Socket connected successfully: ${socket!.id}');
      // If we are currently in a room, re-join it
      if (activeRoomId != null) {
        joinRoom(activeRoomId!);
      }
    });

    socket!.onDisconnect((_) {
      print(' Socket disconnected');
    });

    socket!.onConnectError((err) {
      print(' Socket connect error: $err');
    });

    // Listen to new messages
    socket!.on('new_message', (data) {
      print(' Socket new_message: $data');
      _onNewMessageReceived(data);
    });

    // Listen to messages read confirmations
    socket!.on('messages_read', (data) {
      print(' Socket messages_read: $data');
      _onMessagesRead(data);
    });

    // Listen to price negotiations
    socket!.on('negotiation_update', (data) {
      print(' Socket negotiation_update: $data');
      _onNegotiationUpdated(data);
    });
  }

  void joinRoom(String roomId) {
    activeRoomId = roomId;
    if (socket != null && socket!.connected) {
      socket!.emit('join_room', roomId);
      print(' Emitted join_room for: $roomId');
    }
  }

  void leaveRoom() {
    activeRoomId = null;
  }

  // Fetch all chat rooms
  Future<void> fetchRooms() async {
    _isLoadingRooms = true;
    notifyListeners();
    try {
      final response = await ApiClient().dio.get('/chat/rooms');
      if (response.statusCode == 200) {
        _rooms = response.data['data'] ?? [];
      }
    } catch (e) {
      print('Error fetching rooms: $e');
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  // Fetch message history for a room
  Future<void> fetchMessages(String roomId) async {
    _isLoadingMessages = true;
    _messages.clear();
    notifyListeners();
    try {
      final response = await ApiClient().dio.get('/chat/$roomId/messages');
      if (response.statusCode == 200) {
        _messages = response.data['data'] ?? [];
      }
    } catch (e) {
      print('Error fetching messages: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Create or retrieve a chat room
  Future<Map<String, dynamic>?> createOrGetRoom(String sellerId, String productId) async {
    try {
      final response = await ApiClient().dio.post('/chat/room', data: {
        'sellerId': sellerId,
        'productId': productId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      }
    } on DioException catch (e) {
      print('Error creating/retrieving room: ${e.response?.statusCode} - ${e.response?.data}');
    } catch (e) {
      print('Unexpected error creating/retrieving room: $e');
    }
    return null;
  }

  // Send a message
  Future<void> sendMessage(String roomId, String senderId, String messageText, {String? imageUrl}) async {
    final payload = {
      'roomId': roomId,
      'senderId': senderId,
      'message': messageText,
      'imageUrl': imageUrl,
    };

    if (socket != null && socket!.connected) {
      socket!.emit('send_message', payload);
      print(' Emitted send_message: $payload');
    } else {
      // REST fallback
      try {
        await ApiClient().dio.post('/chat/$roomId/send', data: {
          'message': messageText,
          'imageUrl': imageUrl,
        });
      } catch (e) {
        print('Error sending message via REST fallback: $e');
      }
    }
  }

  // Mark all messages in room as read
  void markMessagesRead(String roomId, String userId) {
    if (socket != null && socket!.connected) {
      socket!.emit('read_messages', {
        'roomId': roomId,
        'userId': userId,
      });
    }

    // Update local unread status immediately
    final index = _rooms.indexWhere((r) => r['id'] == roomId);
    if (index >= 0) {
      _rooms[index]['unreadCount'] = 0;
      notifyListeners();
    }
  }

  void _onNewMessageReceived(dynamic data) {
    final currentUserId = AuthManager().userId;

    if (activeRoomId == data['roomId']) {
      final exists = _messages.any((m) => m['id'] == data['id']);
      if (!exists) {
        _messages.add(data);
        notifyListeners();

        // Automatically mark messages as read if we are actively viewing this chat
        if (data['senderId'] != currentUserId) {
          markMessagesRead(activeRoomId!, currentUserId);
        }
      }
    }

    // Update rooms list
    final roomIndex = _rooms.indexWhere((r) => r['id'] == data['roomId']);
    if (roomIndex >= 0) {
      _rooms[roomIndex]['lastMessage'] = data['message'];
      _rooms[roomIndex]['lastMessageAt'] = data['createdAt'];
      
      // If we are not currently looking at this active room, and the message isn't ours, increment unread count
      if (activeRoomId != data['roomId']) {
        if (data['senderId'] != currentUserId) {
          _rooms[roomIndex]['unreadCount'] = (_rooms[roomIndex]['unreadCount'] ?? 0) + 1;
        }
      }

      // Move room to the top
      final room = _rooms.removeAt(roomIndex);
      _rooms.insert(0, room);
      notifyListeners();
    } else {
      // Fetch rooms to get the new room details
      fetchRooms();
    }
  }

  void _onMessagesRead(dynamic data) {
    final roomId = data['roomId'];
    final userId = data['userId'];
    
    if (activeRoomId == roomId) {
      for (var msg in _messages) {
        if (msg['senderId'] != userId) {
          msg['isRead'] = 1;
        }
      }
      notifyListeners();
    }
  }

  Map<String, dynamic>? get activeRoom {
    if (activeRoomId == null) return null;
    try {
      return _rooms.firstWhere((r) => r['id'] == activeRoomId);
    } catch (_) {
      return null;
    }
  }

  void _onNegotiationUpdated(dynamic data) {
    final roomId = data['roomId'];
    final index = _rooms.indexWhere((r) => r['id'] == roomId);
    if (index >= 0) {
      _rooms[index]['proposedPrice'] = data['proposedPrice'];
      _rooms[index]['negotiationStatus'] = data['negotiationStatus'];
      _rooms[index]['proposedBy'] = data['proposedBy'];
      notifyListeners();
    } else {
      fetchRooms(); // fetch rooms to get the updated details
    }
  }

  Future<bool> proposePrice(String roomId, double price) async {
    try {
      final response = await ApiClient().dio.post('/chat/negotiate/propose', data: {
        'roomId': roomId,
        'price': price,
      });
      if (response.statusCode == 200) {
        final data = response.data['data'];
        _onNegotiationUpdated(data);
        return true;
      }
    } on DioException catch (e) {
      print('Error proposing price: ${e.response?.data}');
    } catch (e) {
      print('Error proposing price: $e');
    }
    return false;
  }

  Future<bool> respondNegotiation(String roomId, String action) async {
    try {
      final response = await ApiClient().dio.post('/chat/negotiate/respond', data: {
        'roomId': roomId,
        'action': action,
      });
      if (response.statusCode == 200) {
        final data = response.data['data'];
        _onNegotiationUpdated(data);
        return true;
      }
    } on DioException catch (e) {
      print('Error responding to negotiation: ${e.response?.data}');
    } catch (e) {
      print('Error responding to negotiation: $e');
    }
    return false;
  }

  void disconnectSocket() {
    if (socket != null) {
      socket!.disconnect();
      socket = null;
      print(' Socket manually disconnected');
    }
    _rooms.clear();
    _messages.clear();
    activeRoomId = null;
    notifyListeners();
  }
}
