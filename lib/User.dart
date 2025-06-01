import '../Playlist.dart';
import '../Music.dart';

class User {

  // Immutable properties
  final String _id;
  final String _username;
  final String _email;
  final DateTime _registrationDate;

  // Mutable properties
  String _password;
  String _fullName;
  String? _profileImageUrl;
  final List<Music> _likedSongs;
  final List<Music> _recentlyPlayed;
  final List<Playlist> _playlists;

  User({
    required String username,
    required String email,
    required String fullName,
    required String password,
    required DateTime registrationDate,
  })  : _username = username,
        _email = email,
        _fullName = fullName,
        _password = password,
        _registrationDate = registrationDate,
        _id = _generateId(username, email),
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
  String get fullName => _fullName;
  String? get profileImageUrl => _profileImageUrl;
  List<Music> get likedSongs => List.unmodifiable(_likedSongs);
  List<Music> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  // Setters for mutable fields
  set password(String value) => _password = value;
  set fullName(String value) => _fullName = value;

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
    return 'User: $_username';
  }
}
