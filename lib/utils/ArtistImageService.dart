import 'package:flutter/material.dart';

class ArtistImageService {
  static final ArtistImageService _instance = ArtistImageService._internal();
  factory ArtistImageService() => _instance;
  ArtistImageService._internal();

  // Cache for storing image URLs to avoid repeated API calls
  final Map<String, String> _imageCache = {};
  
  // Multiple image sources for better reliability
  final List<String> _imageSources = [
    'unsplash', // Unsplash API
    'picsum',   // Picsum Photos
    'placeholder', // Placeholder.com
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
    final String searchQuery = Uri.encodeComponent('$artistName musician artist portrait');
    
    switch (source) {
      case 'unsplash':
        return 'https://source.unsplash.com/100x100/?$searchQuery';
      
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