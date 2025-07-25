import 'dart:convert';
import 'dart:io';
import 'package:second/Response.dart';

import 'Model/Music.dart';
import 'Model/User.dart';
import 'Model/Playlist.dart';
import 'LibraryPage.dart';
import 'Application.dart';

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

  //------------------------------------------------------------------------------
  Future<Map<String, dynamic>> uploadMusic(
    User user,
    Music music,
    String base64Data,
  ) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "uploadMusic",
        "Payload": {
          "userId": user.id,
          "musicMap": music.toMap(includeFilePath: false),
          "base64Data": base64Data,
        },
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();
      // Example response format:
      // {'status': 'uploadMusicSuccess', 'message': 'Music uploaded successfully'}
      // {'status': 'error', 'message': 'Error message'}

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
      // Example response format: (status and payload (list of music maps))
      // {'status': 'getUserMusicListSuccess', 'Payload': [musicMap1, musicMap2, ...]}
      // {'status': 'getUserMusicListSuccess', 'Payload': []}
      // {'status': 'error', 'message': 'Error message'}

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

  Future<Map<String, dynamic>> deleteMusic({
    required User user,
    required Music music,
  }) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "deleteMusic",
        "Payload": {"musicId": music.id, "userId": user.id},
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();

      print('Raw response received: $response');
      // Example response format:
      // {'status': 'deleteMusicSuccess', 'message': 'Music deleted successfully'}
      // {'status': 'error', 'message': 'Error message'}

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
      print('Error deleting music: $e');
      return {"status": "error", "message": "Failed to connect to server"};
    }
  }

  Future<String?> getMusicBase64({
    required User user,
    required Music music,
  }) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "downloadMusic",
        "Payload": {"musicId": music.id, "userId": user.id},
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();

      // Example response format:
      // {'status': 'downloadMusicSuccess', 'Payload': 'base64EncodedString'}
      // {'status': 'error', 'message': 'Error message'}
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

  Future<Map<String, dynamic>> likeSong({
    required User user,
    required Music music,
  }) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );
      // Do not Forget to update the likeCount
      final request = {
        "Request": "likeSong",
        "Payload": {"musicId": music.id, "userId": user.id},
      };
      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();

      // Example response format:
      // {'status': 'likeSuccess', 'message': 'Song liked successfully'}
      // {'status': 'alreadyLiked', 'message': 'Error message'}
      // {'status': 'error', 'message': 'Error message'}

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
      print('Error liking song: $e');
      return {"status": "error", "message": "Failed to connect to server"};
    }
  }

  Future<Map<String, dynamic>> dislikeSong({
    required User user,
    required Music music,
  }) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );
      // Do not Forget to update the likeCount
      final request = {
        "Request": "dislikeSong",
        "Payload": {"musicId": music.id, "userId": user.id},
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();

      // Example response format:
      // {'status': 'dislikeSuccess', 'message': 'Song disliked successfully'}
      // {'status': 'error', 'message': 'Error message'}

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
      print('Error disliking song: $e');
      return {"status": "error", "message": "Failed to connect to server"};
    }
  }

  Future<List<Playlist>> getUserPlaylists(User user) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "getUserPlaylists",
        "Payload": {"userId": user.id},
      };

      socket.write('${jsonEncode(request)}\n\n');
      print("Request sent: ${jsonEncode(request)}");

      final response =
          await socket.cast<List<int>>().transform(const Utf8Decoder()).join();

      // Example response format:
      // {'status': 'getUserPlaylistsSuccess', 'Payload': [playlistMap1, playlistMap2, ...]}
      // {'status': 'getUserPlaylistsSuccess', 'Payload': []}
      // {'status': 'error', 'message': 'Error message'}

      socket.close();

      if (response.isEmpty) {
        print('Error: Empty response from server');
        return [];
      }

      try {
        final List<dynamic> playlistListJson = jsonDecode(response);
        return playlistListJson
            .map((playlistJson) => Playlist.fromMap(playlistJson))
            .toList();
      } catch (e) {
        print('Error decoding response: $e');
        return [];
      }
    } catch (e) {
      print('Error fetching playlists: $e');
      return [];
    }
  }
}
