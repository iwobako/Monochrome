import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
  });

  factory AppUser.fromRpcRow(Map<String, dynamic> row) {
    final id = row['user_id'];
    final name = row['full_name'];
    final email = row['user_email'];
    final isAdmin = row['admin_status'];

    if (id is! String || name is! String || email is! String) {
      throw const FormatException('The account response is incomplete.');
    }
    if (isAdmin is! bool) {
      throw const FormatException(
        'The account response has invalid permissions.',
      );
    }

    return AppUser(id: id, name: name, email: email, isAdmin: isAdmin);
  }

  factory AppUser.fromStoredJson(String value) {
    final data = jsonDecode(value);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('The saved account session is invalid.');
    }

    return AppUser(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      isAdmin: data['isAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'isAdmin': isAdmin,
  };
}

class AppSession extends ChangeNotifier {
  AppSession._();

  static final AppSession instance = AppSession._();
  static const _storageKey = 'monochrome_app_session';

  AppUser? _user;
  AppUser? get user => _user;
  bool get isActive => _user != null;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final storedSession = preferences.getString(_storageKey);
    if (storedSession == null) return;

    try {
      _user = AppUser.fromStoredJson(storedSession);
    } on FormatException {
      await preferences.remove(_storageKey);
    } on TypeError {
      await preferences.remove(_storageKey);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await Supabase.instance.client.rpc(
      'login_user',
      params: {'p_email': email.trim(), 'p_password': password},
    );

    final user = _userFromResponse(
      response,
      emptyMeansInvalidCredentials: true,
    );
    await _saveUser(user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await Supabase.instance.client.rpc(
      'register_user',
      params: {
        'p_name': name.trim(),
        'p_email': email.trim(),
        'p_password': password,
      },
    );

    final user = _userFromResponse(
      response,
      emptyMeansInvalidCredentials: false,
    );
    await _saveUser(user);
  }

  AppUser _userFromResponse(
    dynamic response, {
    required bool emptyMeansInvalidCredentials,
  }) {
    if (response is! List || response.isEmpty) {
      if (emptyMeansInvalidCredentials) {
        throw const InvalidCredentialsException();
      }
      throw const FormatException(
        'The account response did not include a user.',
      );
    }
    if (response.first is! Map) {
      throw const FormatException('The account response is invalid.');
    }

    return AppUser.fromRpcRow(Map<String, dynamic>.from(response.first as Map));
  }

  Future<void> _saveUser(AppUser user) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(user.toJson()),
    );
    if (!saved) {
      throw StateError('Could not save the account session on this device.');
    }

    _user = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    _user = null;
    notifyListeners();
  }
}

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'Email or password is incorrect.';
}
