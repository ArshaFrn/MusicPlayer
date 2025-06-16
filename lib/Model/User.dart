import 'Playlist.dart';
import 'Music.dart';

class User {
  // Immutable properties
  final String _id;
  final String _username;
  final String _email;
  final DateTime _registrationDate;

  // Mutable properties
  String _password;
  String _fullname;
  String? _profileImageUrl;
  final List<Music> _tracks;
  final List<Music> _likedSongs;
  final List<Music> _recentlyPlayed;
  final List<Playlist> _playlists;

  User({
    required String username,
    required String email,
    required String fullname,
    required String password,
    required DateTime registrationDate,
  }) : _username = username,
       _email = email,
       _fullname = fullname,
       _password = password,
       _registrationDate = registrationDate,
       _id = _generateId(username, email),
        _tracks = [],
       _likedSongs = [],
       _recentlyPlayed = [],
       _playlists = [];

  void setProfileImageUrl(String url) {
    _profileImageUrl = url;
  }

  static String _generateId(String username, String email) {
    // TODO: implement a ID logic
    return '';
  }

  // Getters
  String get id => _id;

  String get username => _username;

  String get email => _email;

  DateTime get registrationDate => _registrationDate;

  String get password => _password;

  String get fullname => _fullname;

  String? get profileImageUrl => _profileImageUrl;

  List<Music> get likedSongs => _likedSongs;

  List<Music> get recentlyPlayed => _recentlyPlayed;

  List<Playlist> get playlists => _playlists;

  List<Music> get tracks => _tracks;

  // Setters
  set password(String value) => _password = value;

  set fullname(String value) => _fullname = value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is User && _id == other._id;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() {
    return 'User(id: $_id, username: $_username, email: $_email, fullname: $_fullname, registrationDate: $_registrationDate, profileImageUrl: $_profileImageUrl)';
  }
}
