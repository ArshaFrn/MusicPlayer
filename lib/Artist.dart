import 'Genre.dart';
import 'Music.dart';
import 'Album.dart';

class Artist {
  // Immutable properties
  final String _id;
  final String _name;
  final String _bio;
  final String _profileImageUrl;
  final List<Genre> _genres;

  // Mutable properties
  final List<Music> _songs;
  final List<Album> _albums;

  Artist({
    required String name,
    required String bio,
    required String profileImageUrl,
    List<Genre>? genres,
  }) : _name = name,
       _bio = bio,
       _profileImageUrl = profileImageUrl,
       _genres = genres != null ? List<Genre>.from(genres) : [],
       _id = _generateId(name),
       _songs = [],
       _albums = [];

  static String _generateId(String name) {
    // TODO: implement a complex ID generation logic
    return "";
  }

  // Getters
  String get id => _id;

  String get name => _name;

  String get bio => _bio;

  String get profileImageUrl => _profileImageUrl;

  List<Genre> get genres => List.unmodifiable(_genres);

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
