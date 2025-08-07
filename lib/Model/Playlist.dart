import 'User.dart';
import 'Music.dart';

class Playlist {
  // Immutable properties
  final int _id;

  // Mutable properties
  String _name;
  String _description;
  final List<Music> _tracks;
  bool _isStatic;

  Playlist({
    required String name,
    required String description,
    int? id,
    bool isStatic = false,
    List<Music>? tracks,
  })  : _name = name,
        _description = description,
        _isStatic = isStatic,
        _id = id ?? _generateId(name, description),
        _tracks = tracks ?? [];

  static int _generateId(String name, String description) {
    return (name + description).hashCode;
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      name: map['name'],
      description: map['description'],
      id: map['id'],
      tracks: List<Music>.from(map['tracks']?.map((x) => Music.fromMap(x)) ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': _name,
      'description': _description,
      'tracks': _tracks.map((track) => track.toMap()).toList(),
      'id': _id,
    };
  }

  //Getter
  int get id => _id;
  String get name => _name;
  String get description => _description;
  List<Music> get tracks => _tracks;
  bool get isStatic => _isStatic;

  //Setter
  set name(String value) => _name = value;
  set description(String value) => _description = value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Playlist && _id == other._id;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() {
    return 'Playlist(id: $_id, name: $_name, description: $_description, isStatic: $_isStatic)';
  }
}