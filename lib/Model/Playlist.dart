import 'User.dart';
import 'Music.dart';

class Playlist {

  // Immutable properties
  final int _id;
  final User _owner;
  final DateTime _createdDate;

  // Mutable properties
  String _name;
  String _description;
  final List<Music> _tracks;

  Playlist({
    required String name,
    required User owner,
    required String description,
  })  : _name = name,
        _owner = owner,
        _description = description,
        _createdDate = DateTime.now(),
        _id = _generateId(name, owner),
        _tracks = [];

  static int _generateId(String name, User owner) {
    return (name+owner.username).hashCode;
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      name: map['name'],
      owner: map['owner'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': _name,
      'owner': _owner,
      'description': _description,
    };
  }

  //Getter
  int get id => _id;
  User get owner => _owner;
  DateTime get createdDate => _createdDate;
  String get name => _name;
  String get description => _description;
  List<Music> get tracks => _tracks;

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
    return 'Playlist: $_name (${_owner.toString()})';
  }
}
