import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
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
          "username": user.username,
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
        "Payload": {"username": user.username},
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
        final Map<String, dynamic> responseMap = jsonDecode(response);

        if (responseMap['status'] == 'getUserMusicListSuccess') {
          final List<dynamic> musicListJson = responseMap['Payload'] ?? [];
          return musicListJson
              .map((musicJson) => Music.fromMap(musicJson))
              .toList();
        } else {
          print('Error: Server returned status: ${responseMap['status']}');
          return [];
        }
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
        "Payload": {"musicId": music.id, "username": user.username},
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
    const int maxRetries = 4;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('Download attempt $attempt of $maxRetries');

        final socket = await Socket.connect(serverAddress, serverPort);
        print(
          'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
        );

        final request = {
          "Request": "downloadMusic",
          "Payload": {"musicId": music.id, "username": user.username},
        };

        socket.write('${jsonEncode(request)}\n\n');
        print("Request sent: ${jsonEncode(request)}");

        final StringBuffer responseBuffer = StringBuffer();
        final Completer<String> responseCompleter = Completer<String>();

        socket.listen(
          (List<int> data) {
            final String chunk = String.fromCharCodes(data);
            responseBuffer.write(chunk);
          },
          onError: (error) {
            print('Socket error: $error');
            responseCompleter.completeError(error);
          },
          onDone: () {
            print(
              'Download completed. Total received: ${responseBuffer.length} characters',
            );
            if (!responseCompleter.isCompleted) {
              String fullResponse = responseBuffer.toString();
              responseCompleter.complete(fullResponse);
            }
          },
        );

        final String fullResponse = await responseCompleter.future.timeout(
          Duration(seconds: 120),
          onTimeout: () {
            socket.close();
            throw TimeoutException('Download timeout after 120 seconds');
          },
        );

        socket.close();

        if (fullResponse.isEmpty) {
          print('Error: Empty response from server');
          if (attempt < maxRetries) {
            print('Retrying...');
            continue;
          }
          return null;
        }

        final decoded = jsonDecode(fullResponse);
        if (decoded['status'] == 'downloadMusicSuccess' &&
            decoded['Payload'] != null) {
          var base64Data = decoded['Payload'];
          print(
            'Download completed successfully. Base64 data length: ${base64Data.length}',
          );

          if (fullResponse.length < 1000) {
            print(
              'Error: Response seems too short: ${fullResponse.length} characters',
            );
            if (attempt < maxRetries) {
              print('Retrying...');
              continue;
            }
            return null;
          }

          if (base64Data.isEmpty) {
            print('Error: Empty Base64 data received');
            if (attempt < maxRetries) {
              print('Retrying...');
              continue;
            }
            return null;
          }

          if (base64Data.length % 4 != 0) {
            print(
              'Warning: Base64 string length ${base64Data.length} is not divisible by 4',
            );

            String lastChars = base64Data.substring(
              max(0, base64Data.length - 10),
            );
            bool looksValid = lastChars.contains(RegExp(r'^[A-Za-z0-9+/]*$'));

            if (looksValid) {
              print('Data appears valid, adding standard Base64 padding...');
              String paddedData = base64Data;
              while (paddedData.length % 4 != 0) {
                paddedData += '=';
              }

              try {
                base64Decode(
                  paddedData.substring(0, min(100, paddedData.length)),
                );
                print(
                  'Padding added successfully. New length: ${paddedData.length}',
                );
                base64Data = paddedData;
              } catch (e) {
                print('Error: Invalid Base64 format even with padding: $e');
                if (attempt < maxRetries) {
                  print('Retrying...');
                  continue;
                }
                return null;
              }
            } else {
              print('Data appears truncated, retrying download...');
              if (attempt < maxRetries) {
                print('Retrying...');
                continue;
              }
              return null;
            }
          }
          final String lastChars = base64Data.substring(
            max(0, base64Data.length - 10),
          );
          print('Last 10 characters of Base64: $lastChars');
          print('Base64 data length: ${base64Data.length}');

          return base64Data;
        } else {
          print('Download failed: ${decoded['message'] ?? 'Unknown error'}');
          if (attempt < maxRetries) {
            print('Retrying...');
            continue;
          }
          return null;
        }
      } catch (e) {
        print('Error downloading music (attempt $attempt): $e');
        if (attempt < maxRetries) {
          print('Retrying...');
          continue;
        }
        return null;
      }
    }
    print('All download attempts failed');
    return null;
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
        "Payload": {"musicId": music.id, "username": user.username},
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
        "Payload": {"musicId": music.id, "username": user.username},
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
        "Payload": {"username": user.username},
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

  Future<List<int>> getUserLikedSongs(User user) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "getUserLikedSongs",
        "Payload": {"username": user.username},
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
        final Map<String, dynamic> responseMap = jsonDecode(response);

        if (responseMap['status'] == 'getUserLikedSongsSuccess') {
          final List<dynamic> likedSongIdsJson = responseMap['Payload'] ?? [];
          return likedSongIdsJson.cast<int>();
        } else {
          print('Error: Server returned status: ${responseMap['status']}');
          return [];
        }
      } catch (e) {
        print('Error decoding response: $e');
        return [];
      }
    } catch (e) {
      print('Error fetching liked songs: $e');
      return [];
    }
  }
}
