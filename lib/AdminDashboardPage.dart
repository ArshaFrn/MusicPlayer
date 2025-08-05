import 'package:flutter/material.dart';
import 'Model/Admin.dart';
import 'TcpClient.dart';

class AdminDashboardPage extends StatefulWidget {
  final Admin admin;

  const AdminDashboardPage({super.key, required this.admin});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
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
            itemBuilder: (context) => [
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
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey[900],
            child: Column(
              children: [
                // Admin info
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF8456FF),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        widget.admin.username,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.admin.adminType,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey[700]),
                
                // Navigation items
                Expanded(
                  child: ListView(
                    children: [
                      _buildNavItem(0, 'Dashboard', Icons.dashboard),
                      if (widget.admin.hasCapability(Capability.VIEW_USERS))
                        _buildNavItem(1, 'Users', Icons.people),
                      if (widget.admin.hasCapability(Capability.VIEW_SONGS))
                        _buildNavItem(2, 'Music', Icons.music_note),
                      if (widget.admin.hasCapability(Capability.VIEW_ADMINS))
                        _buildNavItem(3, 'Admins', Icons.admin_panel_settings),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Color(0xFF8456FF) : Colors.grey[400],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Color(0xFF8456FF).withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildUsersManagement();
      case 2:
        return _buildMusicManagement();
      case 3:
        return _buildAdminsManagement();
      default:
        return _buildDashboard();
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
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
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
            children: widget.admin.capabilities.map((capability) {
              return Chip(
                label: Text(
                  capability.toString().split('.').last.replaceAll('_', ' '),
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

  Widget _buildAdminsManagement() {
    return _buildManagementSection(
      'Admins Management',
      Icons.admin_panel_settings,
      'Manage admin accounts and capabilities',
      () => _showAdminsList(),
    );
  }

  Widget _buildManagementSection(String title, IconData icon, String description, VoidCallback onTap) {
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
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
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

  Future<void> _showUsersList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.getAllUsers();

      if (response['status'] == 'getAllUsersSuccess') {
        final users = response['users'] as List;
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

  Future<void> _showMusicList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
      final response = await tcpClient.getAllMusic();

      if (response['status'] == 'getAllMusicSuccess') {
        final music = response['music'] as List;
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
    // This would need to be implemented based on your backend
    _showErrorSnackBar('Admins management not yet implemented');
  }

  void _showUsersDialog(List users) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                trailing: widget.admin.hasCapability(Capability.CHANGE_USERS)
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

  void _showMusicDialog(List music) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              final song = music[index];
              return ListTile(
                title: Text(
                  song['title'] ?? 'Unknown',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  song['artist']?['name'] ?? 'Unknown Artist',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: widget.admin.hasCapability(Capability.CHANGE_SONGS)
                    ? IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMusic(song['id']),
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

  Future<void> _deleteUser(String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Confirm Delete', style: TextStyle(color: Colors.white)),
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
        final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
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

  Future<void> _deleteMusic(int musicId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Confirm Delete', style: TextStyle(color: Colors.white)),
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
        final tcpClient = TcpClient(serverAddress: '10.0.2.2', serverPort: 12345);
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

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