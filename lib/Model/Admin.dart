import 'dart:convert';

enum Capability {
  VIEW_SONGS,
  CHANGE_SONGS,
  VIEW_USERS,
  CHANGE_USERS,
  VIEW_ADMINS,
  CHANGE_ADMINS,
  CREATE_ADMINS,
}

class Admin {
  final String username;
  final String hashedPassword;
  final int? id; // ID for all admins except SuperAdmin
  final Set<Capability> capabilities;
  final String adminType; // "SuperAdmin", "FullAdmin", "LimitedAdmin"

  Admin({
    required this.username,
    required this.hashedPassword,
    this.id,
    required this.capabilities,
    required this.adminType,
  });

  bool hasCapability(Capability capability) {
    return capabilities.contains(capability);
  }

  bool canChangeAdminCapabilities(Admin targetAdmin) {
    switch (adminType) {
      case "SuperAdmin":
        return true; // SuperAdmin can change any admin's capabilities
      case "FullAdmin":
      // FullAdmin can only change capabilities of admins it has registered
      // This would need to be implemented based on your backend logic
        return false; // For now, return false
      case "LimitedAdmin":
        return false; // LimitedAdmin cannot change admin capabilities
      default:
        return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'hashedPassword': hashedPassword,
      'id': id,
      'capabilities': capabilities.map((c) => c.toString().split('.').last).toList(),
      'adminType': adminType,
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    Set<Capability> caps = {};
    List<String> capabilitiesList = List<String>.from(map['capabilities'] ?? []);

    for (String cap in capabilitiesList) {
      switch (cap) {
        case 'VIEW_SONGS':
          caps.add(Capability.VIEW_SONGS);
          break;
        case 'CHANGE_SONGS':
          caps.add(Capability.CHANGE_SONGS);
          break;
        case 'VIEW_USERS':
          caps.add(Capability.VIEW_USERS);
          break;
        case 'CHANGE_USERS':
          caps.add(Capability.CHANGE_USERS);
          break;
        case 'VIEW_ADMINS':
          caps.add(Capability.VIEW_ADMINS);
          break;
        case 'CHANGE_ADMINS':
          caps.add(Capability.CHANGE_ADMINS);
          break;
        case 'CREATE_ADMINS':
          caps.add(Capability.CREATE_ADMINS);
          break;
      }
    }

    return Admin(
      username: map['username'],
      hashedPassword: map['hashedPassword'],
      id: map['id'],
      capabilities: caps,
      adminType: map['adminType'],
    );
  }

  @override
  String toString() {
    return 'Admin(username: $username, type: $adminType, capabilities: $capabilities)';
  }
}