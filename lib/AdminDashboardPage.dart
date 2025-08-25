import 'package:flutter/material.dart';
import 'Model/Admin.dart';
import 'TcpClient.dart';


enum _Section { dashboard, users, music, admins }

class AdminDashboardPage extends StatefulWidget {
  final Admin admin;

  const AdminDashboardPage({super.key, required this.admin});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<_Section> _navSections = [];

  @override
  void initState() {
    super.initState();
    _buildSections();
  }

  void _buildSections() {
    _navSections = [_Section.dashboard];
    if (widget.admin.hasCapability(Capability.VIEW_USERS)) {
      _navSections.add(_Section.users);
    }
    if (widget.admin.hasCapability(Capability.VIEW_SONGS)) {
      _navSections.add(_Section.music);
    }
    if (widget.admin.hasCapability(Capability.VIEW_ADMINS)) {
      _navSections.add(_Section.admins);
    }
    if (_selectedIndex >= _navSections.length) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            SizedBox(width: 10),
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 25),
            SizedBox(width: 8),
            Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pop(context);
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          cardColor: Colors.grey[900],
          appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900]),
          colorScheme: ColorScheme.dark(
            primary: Color(0xFF8456FF),
            secondary: Color(0xFF671BAF),
            surface: Colors.grey[900]!,
            background: Colors.black,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onBackground: Colors.white,
          ),
        ),
        child: _buildContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        items:
            _navSections.map((section) {
              switch (section) {
                case _Section.dashboard:
                  return const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  );
                case _Section.users:
                  return const BottomNavigationBarItem(
                    icon: Icon(Icons.people),
                    label: 'Users',
                  );
                case _Section.music:
                  return const BottomNavigationBarItem(
                    icon: Icon(Icons.music_note),
                    label: 'Music',
                  );
                case _Section.admins:
                  return const BottomNavigationBarItem(
                    icon: Icon(Icons.admin_panel_settings),
                    label: 'Admins',
                  );
              }
            }).toList(),
      ),
    );
  }

  // Returns the page
  Widget _buildContent() {
    final section = _navSections[_selectedIndex];
    switch (section) {
      case _Section.dashboard:
        return _buildDashboard();
      case _Section.users:
        return _buildUsersManagement();
      case _Section.music:
        return _buildMusicManagement();
      case _Section.admins:
        return _buildAdminsManagement();
    }
  }

  Widget _buildDashboard() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${widget.admin.username}!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Admin Type: ${widget.admin.adminType}',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          SizedBox(height: 32),

          // Capabilities
          Text(
            'Your Capabilities:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.admin.capabilities.map((capability) {
                  return Chip(
                    label: Text(
                      capability
                          .toString()
                          .split('.')
                          .last
                          .replaceAll('_', ' '),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: Color(0xFF8456FF),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersManagement() {
    return _buildManagementSection(
      'Users Management',
      Icons.people,
      'Manage user accounts and permissions',
      () => _showUsersList(),
    );
  }

  Widget _buildMusicManagement() {
    return _buildManagementSection(
      'Music Management',
      Icons.music_note,
      'Manage music files and metadata',
      () => _showMusicList(),
    );
  }

  // Page: Admins Management (entry)
  Widget _buildAdminsManagement() {
    return _buildManagementSection(
      'Admins Management',
      Icons.admin_panel_settings,
      'Manage admin accounts and capabilities',
      () => _showAdminsList(),
    );
  }

  // header
  Widget _buildManagementSection(
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF8456FF), size: 32),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _isLoading ? null : onTap,
            icon: Icon(Icons.list),
            label: Text('View List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8456FF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Fetch all users and open the dialog
  Future<void> _showUsersList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.getAllUsers();

      if (response['status'] == 'getAllUsersSuccess') {
        final dynamic payload = response['Payload'] ?? response['users'];
        final List users = payload is List ? payload : [];
        _showUsersDialog(users);
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch all music and open the dialog
  Future<void> _showMusicList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.getAllMusic();

      if (response['status'] == 'getAllMusicSuccess') {
        final dynamic payload = response['Payload'] ?? response['music'];
        final List music = payload is List ? payload : [];
        _showMusicDialog(music);
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to fetch music');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAdminsList() async {
    _showErrorSnackBar('Admins management not yet implemented');
  }

  // Dialog: Users list
  void _showUsersDialog(List users) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Users (${users.length})',
              style: TextStyle(color: Colors.white),
            ),
            content: Container(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(
                      user['username'] ?? 'Unknown',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      user['email'] ?? 'No email',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing:
                        widget.admin.hasCapability(Capability.CHANGE_USERS)
                            ? IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user['username']),
                            )
                            : null,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  // Dialog: Music list
  void _showMusicDialog(List music) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Music (${music.length})',
              style: TextStyle(color: Colors.white),
            ),
            content: Container(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: music.length,
                itemBuilder: (context, index) {
                  final song = music[index] as Map<String, dynamic>;
                  final dynamic artistField = song['artist'];
                  final String artistName =
                      artistField is Map
                          ? (artistField['name']?.toString() ??
                              'Unknown Artist')
                          : (artistField?.toString() ?? 'Unknown Artist');
                  final bool isPublic = (song['isPublic'] == true);
                  return ListTile(
                    title: Text(
                      song['title']?.toString() ?? 'Unknown',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      artistName,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: widget.admin.hasCapability(Capability.CHANGE_SONGS)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPublic ? Icons.lock_open : Icons.lock,
                                  color: isPublic ? Colors.greenAccent : Colors.amber,
                                ),
                                tooltip: isPublic ? 'Make Private' : 'Make Public',
                                onPressed: () => _toggleMusicPublicity(
                                  songId: song['id'],
                                  isCurrentlyPublic: isPublic,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteMusic(song['id']),
                              ),
                            ],
                          )
                        : null,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  Future<void> _toggleMusicPublicity({required int songId, required bool isCurrentlyPublic}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          isCurrentlyPublic ? 'Make Private' : 'Make Public',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          isCurrentlyPublic
              ? 'Are you sure you want to make this song private?'
              : 'Are you sure you want to make this song public?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isCurrentlyPublic ? 'Make Private' : 'Make Public',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
        final response = isCurrentlyPublic
            ? await tcpClient.makeMusicPrivate(widget.admin.username, songId)
            : await tcpClient.makeMusicPublic(widget.admin.username, songId);

        final successStatus = isCurrentlyPublic
            ? 'makeMusicPrivateSuccess'
            : 'makeMusicPublicSuccess';

        if (response['status'] == successStatus) {
          _showSuccessSnackBar(
            isCurrentlyPublic ? 'Song is now private' : 'Song is now public',
          );
          Navigator.pop(context); // Close dialog
          _showMusicList(); // Refresh list
        } else {
          _showErrorSnackBar(response['message'] ?? 'Operation failed');
        }
      } catch (e) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  // Network: Delete a user (with confirmation)
  Future<void> _deleteUser(String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Confirm Delete',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete user "$username"?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final tcpClient = TcpClient(
          serverAddress: '10.0.2.2',
          serverPort: 12345,
        );
        final response = await tcpClient.deleteUser(username);

        if (response['status'] == 'deleteUserSuccess') {
          _showSuccessSnackBar('User deleted successfully');
          Navigator.pop(context); // Close dialog
          _showUsersList(); // Refresh list
        } else {
          _showErrorSnackBar(response['message'] ?? 'Failed to delete user');
        }
      } catch (e) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  // Network: Delete a music (with confirmation)
  Future<void> _deleteMusic(int musicId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Confirm Delete',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete this music?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final tcpClient = TcpClient(
          serverAddress: '10.0.2.2',
          serverPort: 12345,
        );
        final response = await tcpClient.deleteMusic(musicId);

        if (response['status'] == 'deleteMusicSuccess') {
          _showSuccessSnackBar('Music deleted successfully');
          Navigator.pop(context); // Close dialog
          _showMusicList(); // Refresh list
        } else {
          _showErrorSnackBar(response['message'] ?? 'Failed to delete music');
        }
      } catch (e) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  // UI Helper: Error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // UI Helper: Success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
