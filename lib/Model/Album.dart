import 'Artist.dart';
import 'Music.dart';

class Album {
  // Immutable properties
  final int _id;
  final String _title;
  final Artist _artist;
  final String? _coverImagePath; // Path to album cover image

  Album({required String title, required Artist artist, String? coverImagePath})
    : _title = title,
      _artist = artist,
      _coverImagePath = coverImagePath,
      _id = _generateId(title, artist);

  static int _generateId(String title, Artist artist) {
    return (title + artist.name).hashCode;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _id, 
      'title': _title, 
      'artist': _artist.toMap(),
      'coverImagePath': _coverImagePath,
    };
  }

  Album.fromMap(Map<String, dynamic> map)
    : _id = map['id'],
      _title = map['title'],
      _artist = Artist.fromMap(map['artist']),
      _coverImagePath = map['coverImagePath'];

  // Getters
  int get id => _id;

  String get title => _title;

  Artist get artist => _artist;
  
  String? get coverImagePath => _coverImagePath;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Album && _id == other._id;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() {
    return 'Album: $_title by ${_artist.toString()}';
  }
}
