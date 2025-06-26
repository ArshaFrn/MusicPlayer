import 'package:flutter/foundation.dart';

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

  // Mutable properties
  String _filePath;
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
  }) : _title = title,
       _artist = artist,
       _genre = genre,
       _durationInSeconds = durationInSeconds,
       _releaseDate = releaseDate,
       _addedDate = DateTime.now(),
       _album = album,
       _id = _generateId(title, artist, releaseDate),
       _filePath = filePath,
       _likeCount = 0,
       _isLiked = false;

  static int _generateId(String title, Artist artist, DateTime releaseDate) {
    return (title + artist.name + releaseDate.toString()).hashCode;
  }

  Map<String, dynamic> toMap({bool includeFilePath = true}) {
    if (includeFilePath) {
      return {
        'id': _id,
        'title': _title,
        'artist': _artist.toMap(),
        'genre': _genre,
        'durationInSeconds': _durationInSeconds,
        'releaseDate': _releaseDate.toIso8601String(),
        'addedDate': _addedDate.toIso8601String(),
        'album': _album.toMap(),
        'likeCount': _likeCount,
        'isLiked': _isLiked,
        'filePath': _filePath,
      };
    } else {
      return {
        'id': _id,
        'title': _title,
        'artist': _artist.toMap(),
        'genre': _genre,
        'durationInSeconds': _durationInSeconds,
        'releaseDate': _releaseDate.toIso8601String(),
        'addedDate': _addedDate.toIso8601String(),
        'album': _album.toMap(),
        'likeCount': _likeCount,
        'isLiked': _isLiked,
        'filePath': '',
      };
    }
  }

  Music.fromMap(Map<String, dynamic> map)
      : _id = map['id'],
        _title = map['title'],
        _artist = Artist.fromMap(map['artist']),
        _genre = map['genre'],
        _durationInSeconds = map['durationInSeconds'],
        _releaseDate = DateTime.parse(map['releaseDate']),
        _addedDate = DateTime.parse(map['addedDate']),
        _album = Album.fromMap(map['album']),
        _likeCount = map['likeCount'] ?? 0,
        _isLiked = map['isLiked'] ?? false,
        _filePath = map['filePath'] ?? '';

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

  // * Setters
  set likeCount(int value) => _likeCount = value;

  set isLiked(bool value) => _isLiked = value;

  set filePath(String value) => _filePath = value;
  
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
