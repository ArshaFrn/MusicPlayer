import 'Artist.dart';
import 'Genre.dart';
import 'Music.dart';

class Album {

  // Immutable properties
  final String _id;
  final String _title;
  final Artist _artist;
  final DateTime _releaseDate;
  final Genre _genre;
  final String _description;

  // Mutable properties
  String? _coverImageUrl;
  final List<Music> _tracks;

  Album({
    required String title,
    required Artist artist,
    required DateTime releaseDate,
    String? coverImageUrl,
    required Genre genre,
    required String description,
  }) : _title = title,
       _artist = artist,
       _releaseDate = releaseDate,
       _coverImageUrl = coverImageUrl,
       _genre = genre,
       _description = description,
       _id = _generateId(title, artist),
       _tracks = [];

  static String _generateId(String title, Artist artist) {
    // TODO: implement a complex ID generation logic for albums
    return "";
  }

  // Getters
  String get id => _id;

  String get title => _title;

  Artist get artist => _artist;

  DateTime get releaseDate => _releaseDate;

  Genre get genre => _genre;

  String get description => _description;

  String? get coverImageUrl => _coverImageUrl;

  set coverImageUrl(String? url) => _coverImageUrl = url;

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
