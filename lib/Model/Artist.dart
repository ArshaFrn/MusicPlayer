import 'Music.dart';
import 'Album.dart';

class Artist {
  // Immutable properties
  final int _id;
  final String _name;

  Artist({required String name})
    : _name = name,
      _id = _generateId(name);

  static int _generateId(String name) {
    return name.hashCode;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
    };
  }

  Artist.fromMap(Map<String, dynamic> map)
      : _id = map['id'],
        _name = map['name'];

  // Getters
  int get id => _id;

  String get name => _name;

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
