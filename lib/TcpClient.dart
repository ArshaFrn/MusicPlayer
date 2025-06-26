import 'dart:convert';
import 'dart:io';
import 'package:second/Response.dart';

import 'Model/Music.dart';
import 'Model/User.dart';

class TcpClient {
  final String serverAddress;
  final int serverPort;

  TcpClient({required this.serverAddress, required this.serverPort});

  Future<Map<String, dynamic>> signUp(
    String fullname,
    String username,
    String email,
    String password,
  ) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "signUp",
        "Payload": {
          "fullname": fullname,
          "username": username,
          "email": email,
          "password": password,
        },
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();

      socket.close();

      if (response.isEmpty) {
        print('Error: Empty response from server');
        return {"status": "error", "message": "Empty response from server"};
      }

      try {
        return jsonDecode(response);
      } catch (e) {
        print('Error decoding response: $e');
        return {"status": "error", "message": "Invalid response format"};
      }
    } catch (e) {
      print('Error: $e');
      return {"status": "error", "message": "Failed to connect to server"};
    }
  }

  Future<Map<String, dynamic>> logIn(String username, String password) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "logIn",
        "Payload": {"username": username, "password": password},
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();

      print('Raw response received: $response');

      socket.close();

      if (response.isEmpty) {
        print('Error: Empty response from server');
        return {"status": "error", "message": "Empty response from server"};
      }

      try {
        return jsonDecode(response);
      } catch (e) {
        print('Error decoding response: $e');
        return {"status": "error", "message": "Invalid response format"};
      }
    } catch (e) {
      print('Error: $e');
      return {"status": "error", "message": "Failed to connect to server"};
    }
  }

  Future<Map<String, dynamic>> uploadMusic(Music music) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "uploadMusic",
        "Payload": music.toMap(includeFilePath: false),
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();

      print('Raw response received: $response');

      socket.close();

      if (response.isEmpty) {
        print('Error: Empty response from server');
        return {"status": "error", "message": "Empty response from server"};
      }

      try {
        return jsonDecode(response);
      } catch (e) {
        print('Error decoding response: $e');
        return {"status": "error", "message": "Invalid response format"};
      }
    } catch (e) {
      print('Error: $e');
      return {"status": "error", "message": "Failed to connect to server"};
    }
  }

  Future<List<Music>> getUserMusicList(User user) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "getUserMusicList",
        "Payload": {"userId": user.id},
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();

      print('Raw response received: $response');

      socket.close();

      if (response.isEmpty) {
        print('Error: Empty response from server');
        return [];
      }

      try {
        final List<dynamic> musicListJson = jsonDecode(response);
        return musicListJson
            .map((musicJson) => Music.fromMap(musicJson))
            .toList();
      } catch (e) {
        print('Error decoding response: $e');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<String?> getMusicBase64({
    required Music music,
    required User user,
  }) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "downloadMusic",
        "Payload": {"musicId": music.id, "username": user.id},
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();
      socket.close();

      if (response.isEmpty) {
        print('Error: Empty response from server');
        return null;
      }

      final decoded = jsonDecode(response);
      if (decoded['status'] == 'success' && decoded['file'] != null) {
        return decoded['file'];
      } else {
        print('Download failed: ${decoded['message']}');
        return null;
      }
    } catch (e) {
      print('Error downloading music: $e');
      return null;
    }
  }
}
