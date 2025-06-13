import 'Music.dart';
import 'User.dart';

// Applicaation Flow Controller
class Application {
  static final Application _instance = Application._privateConstructor();

  Application._privateConstructor();

  static Application get instance => _instance;

  bool likeMusic(User user, Music music) {
    if (user.likedSongs.contains(music)) {
      unlikeMusic(user, music);
      return false;
    }
    user.likedSongs.add(music);
    return true;
  }

  bool unlikeMusic(User user, Music music) {
    if (!user.likedSongs.contains(music)) {
      likeMusic(user, music);
      return false;
    }
    user.likedSongs.remove(music);
    return true;
  }

}
