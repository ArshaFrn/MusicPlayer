import 'package:flutter/material.dart';
import 'Model/Music.dart';
import 'Model/User.dart';
import 'Application.dart';
import 'SearchPage.dart';
import 'TcpClient.dart';
import 'utils/AudioController.dart';
import 'PlayPage.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';
import 'utils/SnackBarUtils.dart';

class LibraryPage extends StatefulWidget {
  final User user;
  final Function(int) onNavigateToPage;

  const LibraryPage({
    super.key,
    required this.user,
    required this.onNavigateToPage,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final Application application = Application.instance;
  filterOption _selectedSort = filterOption.dateModifiedDesc;
  bool _isLoading = true;
  String _selectedCategory = 'Songs';

  final List<String> _categories = ['Songs', 'Singers', 'Albums', 'Years'];

  @override
  void initState() {
    super.initState();
    _fetchTracksFromServer();
  }

  Future<void> _fetchTracksFromServer() async {
    setState(() {
      _isLoading = true;
    });
    final tcpClient = TcpClient(serverAddress: '192.168.43.173', serverPort: 12345);
    final tracks = await tcpClient.getUserMusicList(widget.user);
    final likedSongIds = await tcpClient.getUserLikedSongs(widget.user);

    setState(() {
      widget.user.tracks
        ..clear()
        ..addAll(tracks);

      widget.user.likedSongs
        ..clear()
        ..addAll(tracks.where((track) => likedSongIds.contains(track.id)));

      for (final track in widget.user.tracks) {
        track.isLiked = likedSongIds.contains(track.id);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var tracks = application.sortTracks(widget.user.tracks, _selectedSort);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Consumer<ThemeProvider>(
          builder: (context, theme, child) {
            return Row(
              children: [
                Icon(
                  Icons.library_music,
                  color: theme.isDarkMode ? Colors.white : Colors.black87,
                  size: 24,
                ),
                const SizedBox(width: 5),
                Text(
                  "Library",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    fontSize: 24,
                    color: theme.isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, theme, child) {
              return IconButton(
                icon: Icon(
                  Icons.search,
                  color: theme.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                tooltip: "Search",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SearchPage(
                            user: widget.user,
                            onNavigateToPage: widget.onNavigateToPage,
                          ),
                    ),
                  );
                },
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, theme, child) {
              return PopupMenuButton<filterOption>(
                icon: Icon(
                  Icons.filter_list,
                  color: theme.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                tooltip: "Filter",
                onSelected: (option) {
                  setState(() {
                    if (application.getBaseSort(_selectedSort) ==
                        application.getBaseSort(option)) {
                      _selectedSort = application.getOppositeSort(
                        _selectedSort,
                      );
                    } else {
                      _selectedSort = option;
                    }
                  });
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: filterOption.dateModifiedDesc,
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.purpleAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Text('Date Modified')),
                            Icon(
                              application.isAscending(_selectedSort) &&
                                      application.getBaseSort(_selectedSort) ==
                                          filterOption.dateModifiedDesc
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color:
                                  application.getBaseSort(_selectedSort) ==
                                          filterOption.dateModifiedDesc
                                      ? Colors.purple
                                      : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      // Title
                      PopupMenuItem(
                        value: filterOption.titleAsc,
                        child: Row(
                          children: [
                            Icon(
                              Icons.sort_by_alpha,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Text('Title')),
                            Icon(
                              application.isAscending(_selectedSort) &&
                                      application.getBaseSort(_selectedSort) ==
                                          filterOption.titleAsc
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color:
                                  application.getBaseSort(_selectedSort) ==
                                          filterOption.titleAsc
                                      ? Colors.blue
                                      : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      // Artist
                      PopupMenuItem(
                        value: filterOption.artistAsc,
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.greenAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Text('Artist')),
                            Icon(
                              application.isAscending(_selectedSort) &&
                                      application.getBaseSort(_selectedSort) ==
                                          filterOption.artistAsc
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color:
                                  application.getBaseSort(_selectedSort) ==
                                          filterOption.artistAsc
                                      ? Colors.green
                                      : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      // Album
                      PopupMenuItem(
                        value: filterOption.albumAsc,
                        child: Row(
                          children: [
                            Icon(
                              Icons.album,
                              color: Colors.orangeAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Text('Album')),
                            Icon(
                              application.isAscending(_selectedSort) &&
                                      application.getBaseSort(_selectedSort) ==
                                          filterOption.albumAsc
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color:
                                  application.getBaseSort(_selectedSort) ==
                                          filterOption.albumAsc
                                      ? Colors.orange
                                      : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      // Duration
                      PopupMenuItem(
                        value: filterOption.durationDesc,
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer,
                              color: Colors.greenAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Text('Duration')),
                            Icon(
                              application.isAscending(_selectedSort) &&
                                      application.getBaseSort(_selectedSort) ==
                                          filterOption.durationDesc
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color:
                                  application.getBaseSort(_selectedSort) ==
                                          filterOption.durationDesc
                                      ? Colors.green
                                      : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      // Like Count
                      PopupMenuItem(
                        value: filterOption.likeCountDesc,
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Text('Like Count')),
                            Icon(
                              application.isAscending(_selectedSort) &&
                                      application.getBaseSort(_selectedSort) ==
                                          filterOption.likeCountDesc
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color:
                                  application.getBaseSort(_selectedSort) ==
                                          filterOption.likeCountDesc
                                      ? Colors.red
                                      : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                offset: Offset(0, 46),
                elevation: 17,
                padding: EdgeInsets.symmetric(vertical: 6),
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, theme, child) {
              return IconButton(
                icon: Icon(
                  Icons.storage,
                  color: theme.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                tooltip: "Cache Management",
                onPressed: () {
                  application.showCacheManagementDialog(context, widget.user);
                },
              );
            },
          ),
        ],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.1,
      ),

      body: Column(
        children: [
          // Category bar
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;

                    return Container(
                      margin: EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : (themeProvider.isDarkMode
                                        ? Colors.white70
                                        : Colors.black54),
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor:
                            themeProvider.isDarkMode
                                ? Color(0xFF8456FF)
                                : Color(0xFFfc6997),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color:
                              isSelected
                                  ? (themeProvider.isDarkMode
                                      ? Color(0xFF8456FF)
                                      : Color(0xFFfc6997))
                                  : (themeProvider.isDarkMode
                                      ? Colors.white30
                                      : Colors.black26),
                          width: 1.5,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _fetchTracksFromServer,
                      child: _buildCategoryContent(tracks),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(List<Music> tracks) {
    switch (_selectedCategory) {
      case 'Songs':
        return _buildSongsView(tracks);
      case 'Singers':
        return _buildSingersView(tracks);
      case 'Albums':
        return _buildAlbumsView(tracks);
      case 'Years':
        return _buildYearsView(tracks);
      default:
        return _buildSongsView(tracks);
    }
  }

  Widget _buildSongsView(List<Music> tracks) {
    if (tracks.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Text(
                    "No tracks available :(\nPlease add some music to your library",
                    style: TextStyle(
                      fontSize: 19,
                      color:
                          themeProvider.isDarkMode
                              ? Colors.blueGrey
                              : Colors.blueGrey[600],
                      fontWeight: FontWeight.bold,
                      height: 1.9,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final music = tracks[index];
        final isLiked = music.isLiked;
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return ListTile(
              onTap: () => _onTrackTap(context, music),
              onLongPress: () => _onTrackLongPress(context, music),
              leading: Icon(
                Icons.music_note,
                color: application.getUniqueColor(music.id, context: context),
              ),
              title: Text(
                music.title,
                style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                music.artist.name,
                style: TextStyle(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    application.formatDuration(music.durationInSeconds),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          themeProvider.isDarkMode
                              ? Colors.white70
                              : Colors.black54,
                    ),
                  ),
                  SizedBox(width: 15),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    transitionBuilder:
                        (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                    child: GestureDetector(
                      key: ValueKey<bool>(isLiked),
                      onTap: () => _onLikeTap(music),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: application.getUniqueColor(
                          music.id,
                          context: context,
                        ),
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSingersView(List<Music> tracks) {
    Map<String, List<Music>> artistGroups = {};
    for (var track in tracks) {
      final artistName = track.artist.name;
      if (!artistGroups.containsKey(artistName)) {
        artistGroups[artistName] = [];
      }
      artistGroups[artistName]!.add(track);
    }

    if (artistGroups.isEmpty) {
      return Center(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Text(
              "No artists found",
              style: TextStyle(
                fontSize: 18,
                color:
                    themeProvider.isDarkMode ? Colors.grey : Colors.grey[600],
              ),
            );
          },
        ),
      );
    }

    return ListView.builder(
      itemCount: artistGroups.length,
      itemBuilder: (context, index) {
        final artistName = artistGroups.keys.elementAt(index);
        final artistTracks = artistGroups[artistName]!;

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return ExpansionTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundColor:
                    themeProvider.isDarkMode
                        ? Color(0xFF8456FF)
                        : Color(0xFFfc6997),
                child: _getDefaultArtistAvatar(artistName),
              ),
              title: Text(
                artistName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                "${artistTracks.length} tracks",
                style: TextStyle(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                ),
              ),
              children:
                  artistTracks
                      .map(
                        (track) => ListTile(
                          leading: Icon(
                            Icons.music_note,
                            color: application.getUniqueColor(
                              track.id,
                              context: context,
                            ),
                          ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            track.album.name ?? 'Unknown Album',
                            style: TextStyle(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          trailing: Text(
                            application.formatDuration(track.durationInSeconds),
                            style: TextStyle(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          onTap: () => _onTrackTap(context, track),
                        ),
                      )
                      .toList(),
            );
          },
        );
      },
    );
  }

  Widget _getDefaultArtistAvatar(String artistName) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: application.getUniqueColor(
              artistName.hashCode,
              context: context,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              artistName[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsView(List<Music> tracks) {
    Map<String, List<Music>> albumGroups = {};
    for (var track in tracks) {
      final albumName = track.album.name ?? 'Unknown Album';
      if (!albumGroups.containsKey(albumName)) {
        albumGroups[albumName] = [];
      }
      albumGroups[albumName]!.add(track);
    }

    if (albumGroups.isEmpty) {
      return Center(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Text(
              "No albums found",
              style: TextStyle(
                fontSize: 18,
                color:
                    themeProvider.isDarkMode ? Colors.grey : Colors.grey[600],
              ),
            );
          },
        ),
      );
    }

    return ListView.builder(
      itemCount: albumGroups.length,
      itemBuilder: (context, index) {
        final albumName = albumGroups.keys.elementAt(index);
        final albumTracks = albumGroups[albumName]!;

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return ExpansionTile(
              leading: CircleAvatar(
                backgroundColor:
                    themeProvider.isDarkMode
                        ? Color(0xFF8456FF)
                        : Color(0xFFfc6997),
                child: Icon(Icons.album, color: Colors.white, size: 30),
              ),
              title: Text(
                albumName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                "${albumTracks.length} tracks",
                style: TextStyle(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                ),
              ),
              children:
                  albumTracks
                      .map(
                        (track) => ListTile(
                          leading: Icon(
                            Icons.music_note,
                            color: application.getUniqueColor(
                              track.id,
                              context: context,
                            ),
                          ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            track.artist.name,
                            style: TextStyle(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          trailing: Text(
                            application.formatDuration(track.durationInSeconds),
                            style: TextStyle(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          onTap: () => _onTrackTap(context, track),
                        ),
                      )
                      .toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildYearsView(List<Music> tracks) {
    Map<int, List<Music>> yearGroups = {};
    for (var track in tracks) {
      final year = track.year;
      if (!yearGroups.containsKey(year)) {
        yearGroups[year] = [];
      }
      yearGroups[year]!.add(track);
    }

    if (yearGroups.isEmpty) {
      return Center(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Text(
              "No tracks found",
              style: TextStyle(
                fontSize: 18,
                color:
                    themeProvider.isDarkMode ? Colors.grey : Colors.grey[600],
              ),
            );
          },
        ),
      );
    }

    final sortedYears =
        yearGroups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedYears.length,
      itemBuilder: (context, index) {
        final year = sortedYears[index];
        final yearTracks = yearGroups[year]!;

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return ExpansionTile(
              leading: CircleAvatar(
                backgroundColor:
                    themeProvider.isDarkMode
                        ? Color(0xFF8456FF)
                        : Color(0xFFfc6997),
                child: Text(
                  year.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              title: Text(
                year.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                "${yearTracks.length} tracks",
                style: TextStyle(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                ),
              ),
              children:
                  yearTracks
                      .map(
                        (track) => ListTile(
                          leading: Icon(
                            Icons.music_note,
                            color: application.getUniqueColor(
                              track.id,
                              context: context,
                            ),
                          ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            "${track.artist.name} • ${track.album.name ?? 'Unknown Album'}",
                            style: TextStyle(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          trailing: Text(
                            application.formatDuration(track.durationInSeconds),
                            style: TextStyle(
                              color:
                                  themeProvider.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          onTap: () => _onTrackTap(context, track),
                        ),
                      )
                      .toList(),
            );
          },
        );
      },
    );
  }

  Future<void> _onTrackLongPress(BuildContext context, Music music) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.play_arrow, color: Colors.blue),
                  title: Text('Play'),
                  onTap: () => Navigator.pop(context, 'play'),
                ),
                ListTile(
                  leading: Icon(Icons.download, color: Colors.green),
                  title: Text('Download'),
                  onTap: () => Navigator.pop(context, 'download'),
                ),
                if (!music.isPublic)
                  ListTile(
                    leading: Icon(Icons.public, color: Colors.orange),
                    title: Text('Make Public'),
                    onTap: () => Navigator.pop(context, 'make_public'),
                  ),
                ListTile(
                  leading: Icon(Icons.share, color: Colors.green),
                  title: Text('Share'),
                  onTap: () => Navigator.pop(context, 'share'),
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete'),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('Details'),
                  onTap: () => Navigator.pop(context, 'details'),
                ),
              ],
            ),
          ),
    );
    if (result == 'play') {
      final success = await application.handleMusicPlayback(
        context: context,
        user: widget.user,
        music: music,
      );
      if (!success) {
        print("Error Playing The Song");
      }
    } else if (result == 'download') {
      await _downloadMusic(music);
    } else if (result == 'make_public') {
      await _makeMusicPublic(music);
    } else if (result == 'share') {
      await application.shareMusic(
        context: context,
        user: widget.user,
        music: music,
      );
    } else if (result == 'delete') {
      await application.deleteMusic(
        context: context,
        user: widget.user,
        music: music,
      );
      setState(() {});
    } else if (result == 'details') {
      application.showMusicDetailsDialog(context, music);
    }
  }

  Future<void> _downloadMusic(Music music) async {
    try {
      SnackBarUtils.showInfoSnackBar(context, "Downloading ${music.title}...");
      final success = await application.downloadMusic(widget.user, music);

      if (success) {
        SnackBarUtils.showSuccessSnackBar(
          context,
          "${music.title} downloaded successfully!",
        );
      } else {
        SnackBarUtils.showErrorSnackBar(
          context,
          "Failed to download ${music.title}",
        );
      }
    } catch (e) {
      SnackBarUtils.showErrorSnackBar(context, "Error downloading: $e");
    }
  }

  Future<void> _makeMusicPublic(Music music) async {
    try {
      SnackBarUtils.showWarningSnackBar(
        context,
        "Making ${music.title} public...",
      );
      
      final success = await application.makeMusicPublic(widget.user, music);

      if (success) {
        setState(() {
          music.isPublic = true;
        });
        SnackBarUtils.showSuccessSnackBar(
          context,
          "${music.title} is now public!",
        );
      } else {
        SnackBarUtils.showErrorSnackBar(
          context,
          "Failed to make ${music.title} public",
        );
      }
    } catch (e) {
      SnackBarUtils.showErrorSnackBar(context, "Error making public: $e");
    }
  }

  Future<void> _onLikeTap(Music music) async {
    final success = await application.toggleLike(widget.user, music);
    if (success) {
      setState(() {});
    } else {
      SnackBarUtils.showErrorSnackBar(context, 'Error toggling like');
    }
  }

  Future<void> _onTrackTap(BuildContext context, Music music) async {
    try {
      final audioController = AudioController.instance;
      if (audioController.hasTrack &&
          audioController.currentTrack!.id == music.id) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PlayPage(
                  music: music,
                  user: widget.user,
                  playlist: widget.user.tracks,
                ),
          ),
        );
        return;
      }

      final success = await application.handleMusicPlayback(
        context: context,
        user: widget.user,
        music: music,
      );

      if (!success) {
        print("Error Playing The Song");
      }
    } catch (e) {
      print('Error handling track tap: $e');
      SnackBarUtils.showErrorSnackBar(context, 'Error playing music');
    }
  }
}
