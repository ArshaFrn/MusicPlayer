import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ArtistImageService {
  static final ArtistImageService _instance = ArtistImageService._internal();
  factory ArtistImageService() => _instance;
  ArtistImageService._internal();

  // Cache for storing image URLs to avoid repeated API calls
  final Map<String, String> _imageCache = {};
  
  // Unsplash API credentials
  static const String _unsplashAccessKey = 'S7BrM36fSWv3puPp_dTc3wIC-6-a8zz9QQynuFYCl0Q';
  static const String _unsplashApplicationId = '792523';
  static const String _unsplashSecretKey = 'jTPxpOaSnX_K2VtjO15xba2TESbT97gNAuYWw-F4Reg';
  
  // Rate limiting - delay between requests to avoid being banned
  static const int _requestDelayMs = 2000; // 2 seconds delay
  DateTime? _lastRequestTime;
  
  // Multiple image sources for better reliability
  final List<String> _imageSources = [
    'unsplash', // Unsplash API (primary)
    'picsum',   // Picsum Photos (fallback)
    'placeholder', // Placeholder.com (final fallback)
  ];

  /// Get artist image URL from multiple sources
  Future<String?> getArtistImageUrl(String artistName) async {
    // Check cache first
    if (_imageCache.containsKey(artistName)) {
      return _imageCache[artistName];
    }

    // Try different image sources
    for (String source in _imageSources) {
      try {
        String? imageUrl = await _getImageFromSource(artistName, source);
        if (imageUrl != null) {
          // Cache the successful result
          _imageCache[artistName] = imageUrl;
          return imageUrl;
        }
      } catch (e) {
        print('Error getting image from $source for $artistName: $e');
        continue;
      }
    }

    return null;
  }

  /// Get image URL from a specific source
  Future<String?> _getImageFromSource(String artistName, String source) async {
    switch (source) {
      case 'unsplash':
        return await _getUnsplashImage(artistName);
      
      case 'picsum':
        // Use artist name hash for consistent but different images
        final int hash = artistName.hashCode;
        return 'https://picsum.photos/100/100?random=${hash.abs()}';
      
      case 'placeholder':
        // Simple placeholder with artist initial
        final String initial = artistName.isNotEmpty ? artistName[0].toUpperCase() : 'A';
        return 'https://via.placeholder.com/100x100/8456FF/FFFFFF?text=$initial';
      
      default:
        return null;
    }
  }

  /// Get image from Unsplash API with rate limiting
  Future<String?> _getUnsplashImage(String artistName) async {
    // Rate limiting - ensure delay between requests
    await _enforceRateLimit();
    
    try {
      // Clean the artist name for better search results
      String cleanArtistName = artistName.trim();
      
      // Remove common prefixes/suffixes that might interfere with search
      cleanArtistName = cleanArtistName.replaceAll(RegExp(r'^@'), ''); // Remove @ prefix
      cleanArtistName = cleanArtistName.replaceAll(RegExp(r'[^\w\s]'), ' '); // Remove special characters
      cleanArtistName = cleanArtistName.trim();
      
      // Create multiple search strategies for better results
      final List<String> searchQueries = [
        cleanArtistName, // Direct artist name
        '$cleanArtistName musician', // Artist + musician
        '$cleanArtistName singer', // Artist + singer
        '$cleanArtistName artist', // Artist + artist
        '$cleanArtistName portrait', // Artist + portrait
      ];
      
      // Try each search query until we find a result
      for (String query in searchQueries) {
        final encodedQuery = Uri.encodeComponent(query);
        final result = await _tryUnsplashSearch(encodedQuery);
        if (result != null) {
          print('Found image for "$artistName" using query: "$query"');
          return result;
        }
      }
      
      // If all searches fail, try a random image with the artist name
      return await _getRandomUnsplashImage(cleanArtistName);
      
    } catch (e) {
      print('Error fetching from Unsplash for $artistName: $e');
      return null;
    }
  }

  /// Try a specific search query on Unsplash
  Future<String?> _tryUnsplashSearch(String encodedQuery) async {
    try {
      final searchUrl = 'https://api.unsplash.com/search/photos?query=$encodedQuery&per_page=3&orientation=portrait';
      
      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'Authorization': 'Client-ID $_unsplashAccessKey',
          'Accept-Version': 'v1',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        if (results.isNotEmpty) {
          // Return the first result (most relevant)
          final photo = results.first;
          final imageUrl = photo['urls']['regular'] as String;
          return imageUrl;
        }
      }
    } catch (e) {
      print('Error in Unsplash search with query $encodedQuery: $e');
    }
    
    return null;
  }

  /// Get a random image from Unsplash
  Future<String?> _getRandomUnsplashImage(String artistName) async {
    try {
      final encodedQuery = Uri.encodeComponent(artistName);
      final randomUrl = 'https://api.unsplash.com/photos/random?query=$encodedQuery&orientation=portrait';
      
      final response = await http.get(
        Uri.parse(randomUrl),
        headers: {
          'Authorization': 'Client-ID $_unsplashAccessKey',
          'Accept-Version': 'v1',
        },
      );

      if (response.statusCode == 200) {
        final photo = json.decode(response.body);
        return photo['urls']['regular'] as String;
      }
    } catch (e) {
      print('Error fetching random image from Unsplash for $artistName: $e');
    }
    
    return null;
  }

  /// Enforce rate limiting to avoid being banned
  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      final remainingDelay = Duration(milliseconds: _requestDelayMs) - timeSinceLastRequest;
      
      if (remainingDelay.isNegative == false) {
        await Future.delayed(remainingDelay);
      }
    }
    
    _lastRequestTime = DateTime.now();
  }

  /// Clear the image cache
  void clearCache() {
    _imageCache.clear();
  }

  /// Remove specific artist from cache
  void removeFromCache(String artistName) {
    _imageCache.remove(artistName);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'total_cached': _imageCache.length,
      'cached_artists': _imageCache.keys.toList(),
    };
  }
}

/// Widget for displaying artist images with dynamic loading
class ArtistImageWidget extends StatefulWidget {
  final String artistName;
  final double size;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const ArtistImageWidget({
    Key? key,
    required this.artistName,
    this.size = 50.0,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<ArtistImageWidget> createState() => _ArtistImageWidgetState();
}

class _ArtistImageWidgetState extends State<ArtistImageWidget> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadArtistImage();
  }

  @override
  void didUpdateWidget(ArtistImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artistName != widget.artistName) {
      _loadArtistImage();
    }
  }

  Future<void> _loadArtistImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final imageService = ArtistImageService();
      final imageUrl = await imageService.getArtistImageUrl(widget.artistName);
      
      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError || _imageUrl == null) {
      return _buildErrorWidget();
    }

    return ClipOval(
      child: Image.network(
        _imageUrl!,
        width: widget.size,
        height: widget.size,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
        loadingBuilder: widget.loadingBuilder ?? (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
        headers: {
          'Cache-Control': 'max-age=86400', // Cache for 24 hours
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, widget.artistName);
    }

    // Default error widget with artist initial
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
} 