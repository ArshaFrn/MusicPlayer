import 'Artist.dart';
import 'Album.dart';
import 'Genre.dart';

class Music {

  // Immutable properties
  final String _id;
  final String _title;
  final Artist _artist;
  final Genre _genre;
  final int _durationInSeconds;
  final DateTime _releaseDate;
  final DateTime _addedDate;
  final Album _album;

  // Mutable properties
  int _likeCount = 0;
  bool _isLiked = false;

  Music({
    required String title,
    required Artist artist,
    required Genre genre,
    required int durationInSeconds,
    required DateTime releaseDate,
    required Album album,
  })  : _title = title,
        _artist = artist,
        _genre = genre,
        _durationInSeconds = durationInSeconds,
        _releaseDate = releaseDate,
        _addedDate = DateTime.now(),
        _album = album,
        _id = _generateId(title, artist, releaseDate),
        _likeCount = 0,
        _isLiked = false;

  static String _generateId(String title, Artist artist, DateTime releaseDate) {
    // TODO: implement a complex ID generation logic
    return "";
  }

  // * Getters
  String get id => _id;
  String get title => _title;
  Artist get artist => _artist;
  Genre get genre => _genre;
  int get durationInSeconds => _durationInSeconds;
  DateTime get releaseDate => _releaseDate;
  DateTime get addedDate => _addedDate;
  Album get album => _album;
  int get likeCount => _likeCount;
  bool get isLiked => _isLiked;

  // * Setters
  set likeCount(int value) => _likeCount = value;
  set isLiked(bool value) => _isLiked = value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Music && _id == other._id;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() {
    return 'Track: $_title by ${_artist.toString()}';
  }
}
