import 'package:flutter/material.dart';
import 'dart:io';
import 'Model/User.dart';
import 'Application.dart';
import 'Model/Music.dart';
import 'TcpClient.dart';
import 'package:provider/provider.dart';
import 'utils/ThemeProvider.dart';

class AddPage extends StatefulWidget {
  final User _user;
  final Function(int) onNavigateToPage;

  const AddPage({
    super.key, 
    required User user, 
    required this.onNavigateToPage,
  }) : _user = user;

  @override
  State<AddPage> createState() => _AddPage();
}

class _AddPage extends State<AddPage> {
  final Application application = Application.instance;
  List<Music> _publicMusics = [];
  List<Music> _filteredMusics = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = 'Title'; // New: track selected sort option

  // New: sort options
  final List<String> _sortOptions = ['Title', 'Artist', 'Album', 'Duration', 'Likes'];

  @override
  void initState() {
    super.initState();
    _fetchPublicMusics();
    _searchController.addListener(_filterMusics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMusics() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredMusics = _publicMusics;
      });
    } else {
      setState(() {
        _filteredMusics = _publicMusics.where((music) {
          return music.title.toLowerCase().contains(query) ||
                 music.artist.name.toLowerCase().contains(query) ||
                 (music.album?.name.toLowerCase().contains(query) ?? false);
        }).toList();
      });
    }
    _sortMusics(); // Apply sorting after filtering
  }

  void _sortMusics() {
    final List<Music> musicsToSort = List.from(_filteredMusics);
    
    switch (_selectedSort) {
      case 'Title':
        musicsToSort.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Artist':
        musicsToSort.sort((a, b) => a.artist.name.toLowerCase().compareTo(b.artist.name.toLowerCase()));
        break;
      case 'Album':
        musicsToSort.sort((a, b) => (a.album?.name ?? '').toLowerCase().compareTo((b.album?.name ?? '').toLowerCase()));
        break;
      case 'Duration':
        musicsToSort.sort((a, b) => a.durationInSeconds.compareTo(b.durationInSeconds));
        break;
      case 'Likes':
        musicsToSort.sort((a, b) => (a.likeCount ?? 0).compareTo(b.likeCount ?? 0));
        break;
    }
    
    setState(() {
      _filteredMusics = musicsToSort;
    });
  }

  Future<void> _fetchPublicMusics() async {
    if (_isRefreshing) return;

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final publicMusics = await tcpClient.getPublicMusicList();

      setState(() {
        _publicMusics = publicMusics;
        _filteredMusics = publicMusics; // Initialize filtered list with all public musics
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      print('Error fetching public musics: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshPublicMusics() async {
    await _fetchPublicMusics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ThemeProvider>(
          builder: (context, theme, child) {
            return Row(
              children: [
                Icon(
                  Icons.add_circle, 
                  color: theme.isDarkMode ? Colors.white : Colors.black87, 
                  size: 24
                ),
                const SizedBox(width: 5),
                Text(
                  "Add Music",
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
          IconButton(
            icon: Icon(
              _isRefreshing ? Icons.refresh : Icons.refresh_outlined,
              color: _isRefreshing ? Colors.orange : Colors.white70,
            ),
            tooltip: "Refresh Public Music",
            onPressed: _isRefreshing ? null : _refreshPublicMusics,
          ),
        ],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.1,
      ),
      body: Column(
        children: [
          // Search bar
          Consumer<ThemeProvider>(
            builder: (context, theme, child) {
              return Container(
                padding: EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, or albums...',
                    hintStyle: TextStyle(color: theme.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: theme.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    filled: true,
                    fillColor: theme.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  style: TextStyle(color: theme.isDarkMode ? Colors.white : Colors.black87),
                ),
              );
            },
          ),

          // Sort options bar
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sortOptions.length,
              itemBuilder: (context, index) {
                final option = _sortOptions[index];
                final isSelected = _selectedSort == option;
                
                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: Consumer<ThemeProvider>(
                    builder: (context, theme, child) {
                      return ChoiceChip(
                        label: Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (theme.isDarkMode ? Colors.white70 : Colors.black54),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: theme.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: isSelected 
                              ? (theme.isDarkMode ? Color(0xFF8456FF) : Color(0xFFfc6997))
                              : (theme.isDarkMode ? Colors.white30 : Colors.black26),
                          width: 1.5,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedSort = option;
                            _sortMusics();
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Header section
          Consumer<ThemeProvider>(
            builder: (context, theme, child) {
              return Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.public, 
                      color: theme.isDarkMode ? Colors.purpleAccent : Color(0xFFfc6997), 
                      size: 24
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Public Music Library",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Spacer(),
                    Text(
                      "${_filteredMusics.length} tracks",
                      style: TextStyle(
                        fontSize: 14, 
                        color: theme.isDarkMode ? Colors.grey[400] : Colors.grey[600]
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Public music list
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _refreshPublicMusics,
                      child:
                          _filteredMusics.isEmpty
                              ? ListView(
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.5,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.music_off,
                                            size: 64,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            _searchController.text.isEmpty
                                                ? "No public music available"
                                                : "No results found",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey[400],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            _searchController.text.isEmpty
                                                ? "Be the first to share music!"
                                                : "Try different search terms",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                itemCount: _filteredMusics.length,
                                itemBuilder: (context, index) {
                                  final music = _filteredMusics[index];
                                  final isAlreadyAdded = widget._user.tracks
                                      .any((m) => m.id == music.id);

                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    color: Colors.grey[900],
                                    child: ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: application.getUniqueColor(
                                            music.id,
                                            context: context,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.music_note,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        music.title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            music.artist.name,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          if (music.album?.name != null)
                                            Text(
                                              music.album!.name,
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Like count
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.favorite,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "${music.likeCount ?? 0}",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          // Add button or Added indicator
                                          isAlreadyAdded
                                              ? Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  "Added",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              )
                                              : IconButton(
                                                icon: Icon(
                                                  Icons.add_circle_outline,
                                                  color: application
                                                      .getUniqueColor(music.id, context: context),
                                                  size: 28,
                                                ),
                                                onPressed:
                                                    () =>
                                                        _addPublicMusicToLibrary(
                                                          music,
                                                        ),
                                              ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 20, right: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 72, 9, 145),
              Color.fromARGB(255, 123, 31, 162),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _handlePickMusicFile,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.upload, color: Colors.white, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }



  Future<void> _handlePickMusicFile() async {
    final file = await application.pickMusicFile();
    if (file != null) {
      final music = await application.buildMusicObject(file);
      if (music != null) {
        final alreadyExists = widget._user.tracks.any((m) => m.id == music.id);
        if (alreadyExists) {
          _showSnackBar(
            context,
            "This music is already in your library.",
            Icons.error,
            Colors.orange,
          );
          return;
        }

        // Show public/private choice dialog
        final bool? isPublic = await _showPublicPrivateDialog(context, music);
        if (isPublic == null) {
          // User cancelled
          return;
        }

        await _uploadMusic(music, file, isPublic);
      } else {
        _showSnackBar(
          context,
          "Failed to create music object.",
          Icons.error,
          Colors.red,
        );
      }
    } else {
      _showSnackBar(context, "No file selected.", Icons.warning, Colors.orange);
    }
  }

  Future<bool?> _showPublicPrivateDialog(
    BuildContext context,
    Music music,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Icon(Icons.public, color: Colors.purpleAccent, size: 28),
                SizedBox(width: 10),
                Text(
                  "Make it Public?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Do you want to make \"${music.title}\" public?",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.public, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Public: Other users can discover and add your music",
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Private: Only you can access this music",
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Private", style: TextStyle(color: Colors.orange)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                ),
                child: Text("Public"),
              ),
            ],
          ),
    );
  }

  Future<void> _uploadMusic(Music music, dynamic file, bool isPublic) async {
    final tcpClient = TcpClient(serverAddress: "10.0.2.2", serverPort: 12345);

    String? base64Data = await application.encodeFile(file);
    if (base64Data == null) {
      _showSnackBar(
        context,
        "Failed to encode file to Base64.",
        Icons.error,
        Colors.red,
      );
      return;
    }

    final response = await tcpClient.uploadMusic(
      widget._user,
      music,
      base64Data,
      isPublic: isPublic,
    );
    base64Data = null; // Clear the variable to free memory

    if (response['status'] == 'uploadMusicSuccess') {
      _showSnackBar(
        context,
        response['message'] ??
            "Added: ${music.title} (${isPublic ? 'Public' : 'Private'})",
        Icons.check_circle,
        Colors.green,
      );
      setState(() {
        widget._user.tracks.add(music);
      });

      // Refresh public music list if we added a public music
      if (isPublic) {
        await _fetchPublicMusics();
      }
    } else if (response['status'] == 'musicAlreadyExists') {
      _showSnackBar(
        context,
        response['message'] ?? "Music already exists in your library",
        Icons.info,
        Colors.blue,
      );
    } else {
      _showSnackBar(
        context,
        "Failed to add music: ${response['message'] ?? 'Unknown error'}",
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _addPublicMusicToLibrary(Music music) async {
    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.addMusicToLibrary(
        widget._user.username,
        music,
      );

      // Handle different response statuses based on server response
      switch (response['status']) {
        case 'addMusicSuccess':
          setState(() {
            widget._user.tracks.add(music);
            // Sync the like state for the newly added track
            application.syncLikeState(widget._user, [music]);
          });
          _showSnackBar(
            context,
            response['message'] ?? "Music added to library: ${music.title}",
            Icons.check_circle,
            Colors.green,
          );
          break;

        case 'musicAlreadyExists':
          _showSnackBar(
            context,
            response['message'] ?? "Music already exists in your library",
            Icons.info,
            Colors.blue,
          );
          break;

        case 'userNotFound':
          _showSnackBar(
            context,
            response['message'] ?? "User not found",
            Icons.error,
            Colors.red,
          );
          break;

        case 'musicNotFound':
          _showSnackBar(
            context,
            response['message'] ?? "Music not found",
            Icons.error,
            Colors.red,
          );
          break;

        case 'addMusicFailed':
          _showSnackBar(
            context,
            response['message'] ?? "Failed to add music to library",
            Icons.error,
            Colors.red,
          );
          break;

        default:
          _showSnackBar(
            context,
            response['message'] ?? "Unknown error occurred",
            Icons.error,
            Colors.red,
          );
          break;
      }
    } catch (e) {
      _showSnackBar(
        context,
        "Connection error: ${e.toString()}",
        Icons.error,
        Colors.red,
      );
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    IconData icon,
    Color iconColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 52, 21, 57),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.all(14),
      ),
    );
  }
}
