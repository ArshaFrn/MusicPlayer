import 'Music.dart';
import 'Album.dart';

class Artist {
  // Immutable properties
  final int _id;
  final String _name;

  // Mutable properties
  final List<Music> _songs;
  final List<Album> _albums;

  Artist({required String name})
    : _name = name,
      _id = _generateId(name),
      _songs = [],
      _albums = [];

  static int _generateId(String name) {
    return name.hashCode;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'songs': _songs.map((song) => song.toMap()).toList(),
      'albums': _albums.map((album) => album.toMap()).toList(),
    };
  }

  Artist.fromMap(Map<String, dynamic> map)
      : _id = map['id'],
        _name = map['name'],
        _songs = (map['songs'] as List<dynamic>)
            .map((song) => Music.fromMap(song))
            .toList(),
        _albums = (map['albums'] as List<dynamic>)
            .map((album) => Album.fromMap(album))
            .toList();

  // Getters
  int get id => _id;

  String get name => _name;

  List<Music> get songs => _songs;

  List<Album> get albums => _albums;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Artist && _id == other._id;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() {
    return 'Artist: $_name';
  }
}
