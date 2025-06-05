import 'dart:convert';
import 'dart:io';

class TcpClient {
  final String serverAddress;
  final int serverPort;

  TcpClient({required this.serverAddress, required this.serverPort});

  Future<Map<String, dynamic>> signUpCheck(
    String username,
    String email,
  ) async {
    try {
      final socket = await Socket.connect(serverAddress, serverPort);
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "signUpCheck",
        "Payload": {"username": username, "email": email},
      };

      socket.write(jsonEncode(request));
      print('Request sent: $request');

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

  Future<Map<String, dynamic>> logInCheck(
    String username,
    String password,
  ) async {
    final socket = await Socket.connect(serverAddress, serverPort);
    try {
      print(
        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}',
      );

      final request = {
        "Request": "logInCheck",
        "Payload": {"username": username, "password": password},
      };

      socket.write(jsonEncode(request));
      print('Request sent: $request');

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
}
