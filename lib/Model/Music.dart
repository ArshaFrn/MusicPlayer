import 'Artist.dart';
import 'Album.dart';

class Music {
  // Immutable properties
  final int _id;
  final String _title;
  final Artist _artist;
  final String _genre;
  final int _durationInSeconds;
  final DateTime _releaseDate;
  final DateTime _addedDate;
  final Album _album;
  final String _filePath;
  final String _base64Data;

  // Mutable properties
  int _likeCount = 0;
  bool _isLiked = false;

  Music({
    required String title,
    required Artist artist,
    required String genre,
    required int durationInSeconds,
    required DateTime releaseDate,
    required Album album,
    required filePath,
    required base64Data,
  }) : _title = title,
       _artist = artist,
       _genre = genre,
       _durationInSeconds = durationInSeconds,
       _releaseDate = releaseDate,
       _addedDate = DateTime.now(),
       _album = album,
       _id = _generateId(title, artist, releaseDate),
       _filePath = filePath,
       _base64Data = base64Data,
       _likeCount = 0,
       _isLiked = false;

  static int _generateId(String title, Artist artist, DateTime releaseDate) {
    return (title + artist.name + releaseDate.toString()).hashCode;
  }

  // * Getters
  int get id => _id;

  String get title => _title;

  Artist get artist => _artist;

  String get genre => _genre;

  int get durationInSeconds => _durationInSeconds;

  DateTime get releaseDate => _releaseDate;

  DateTime get addedDate => _addedDate;

  Album get album => _album;

  int get likeCount => _likeCount;

  bool get isLiked => _isLiked;

  String get filePath => _filePath;

  String get base64Data => _base64Data;

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
