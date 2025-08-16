// This is an example of how you could implement Google Custom Search API
// for more advanced artist image search. This would require a backend server.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AdvancedImageSearchExample {
  // You would need to set up a backend server with these credentials
  static const String _apiKey = 'YOUR_GOOGLE_CUSTOM_SEARCH_API_KEY';
  static const String _searchEngineId = 'YOUR_GOOGLE_CUSTOM_SEARCH_ENGINE_ID';
  static const String _backendUrl = 'https://your-backend-server.com/api';

  /// Get artist image using Google Custom Search API via backend
  static Future<String?> getArtistImageFromGoogleSearch(String artistName) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/image?name=${Uri.encodeComponent(artistName)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['image_url'];
      }
    } catch (e) {
      print('Error fetching image from Google Search: $e');
    }
    return null;
  }

  /// Alternative: Direct Google Custom Search API call (requires API key)
  static Future<String?> getArtistImageDirect(String artistName) async {
    try {
      final url = Uri.parse('https://www.googleapis.com/customsearch/v1');
      final params = {
        'key': _apiKey,
        'cx': _searchEngineId,
        'q': '$artistName musician artist portrait',
        'searchType': 'image',
        'num': '1',
        'imgSize': 'medium',
        'imgType': 'face',
      };

      final response = await http.get(url.replace(queryParameters: params));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0]['link'];
        }
      }
    } catch (e) {
      print('Error with direct Google Search API: $e');
    }
    return null;
  }
}

/// Example backend server code (Python Flask)
/*
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

API_KEY = "YOUR_GOOGLE_CUSTOM_SEARCH_API_KEY"
SEARCH_ENGINE_ID = "YOUR_GOOGLE_CUSTOM_SEARCH_ENGINE_ID"

def get_image_url(search_term, api_key, search_engine_id):
    url = "https://www.googleapis.com/customsearch/v1"
    params = {
        "key": api_key,
        "cx": search_engine_id,
        "q": search_term,
        "searchType": "image",
        "num": 1,
        "imgSize": "medium",
        "imgType": "face",
    }

    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        data = response.json()

        if "items" in data and len(data["items"]) > 0:
            return data["items"][0]["link"]
        else:
            return None

    except Exception as e:
        print(f"Error during API request: {e}")
        return None

@app.route('/api/image')
def get_image():
    name = request.args.get('name')
    if not name:
        return jsonify({'error': 'Name parameter is required'}), 400

    search_term = f"{name} musician artist portrait"
    image_url = get_image_url(search_term, API_KEY, SEARCH_ENGINE_ID)

    if image_url:
        return jsonify({'image_url': image_url})
    else:
        return jsonify({'error': 'No image found for that name'}), 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
*/

/// Example usage in Flutter widget
class AdvancedArtistImageWidget extends StatefulWidget {
  final String artistName;
  final double size;

  const AdvancedArtistImageWidget({
    Key? key,
    required this.artistName,
    this.size = 50.0,
  }) : super(key: key);

  @override
  State<AdvancedArtistImageWidget> createState() => _AdvancedArtistImageWidgetState();
}

class _AdvancedArtistImageWidgetState extends State<AdvancedArtistImageWidget> {
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try Google Custom Search first
      String? imageUrl = await AdvancedImageSearchExample.getArtistImageFromGoogleSearch(widget.artistName);
      
      if (imageUrl == null) {
        // Fallback to Unsplash
        final searchQuery = Uri.encodeComponent('${widget.artistName} musician artist portrait');
        imageUrl = 'https://source.unsplash.com/100x100/?$searchQuery';
      }

      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_imageUrl == null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Color(0xFF8456FF),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            widget.artistName.isNotEmpty ? widget.artistName[0].toUpperCase() : 'A',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: widget.size * 0.4,
            ),
          ),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        _imageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Color(0xFF8456FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.artistName.isNotEmpty ? widget.artistName[0].toUpperCase() : 'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.size * 0.4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 