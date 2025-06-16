import 'Artist.dart';
import 'Music.dart';

class Album {
  // Immutable properties
  final int _id;
  final String _title;
  final Artist _artist;

  // Mutable properties
  final List<Music> _tracks;

  Album({required String title, required Artist artist})
    : _title = title,
      _artist = artist,
      _id = _generateId(title, artist),
      _tracks = [];

  static int _generateId(String title, Artist artist) {
    return (title + artist.name).hashCode;
  }

  // Getters
  int get id => _id;

  String get title => _title;

  Artist get artist => _artist;

  List<Music> get tracks => _tracks;

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
