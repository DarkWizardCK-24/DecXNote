import 'package:deck_note/models/user_model.dart';
import 'package:deck_note/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  StreamSubscription<String?>? _authStateSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider({AuthService? service})
    : _authService = service ?? FirebaseAuthService() {
    _initAuthStateListener();
  }

  void _initAuthStateListener() {
    _authStateSubscription = _authService.authStateChanges.listen((
      uid,
    ) async {
      if (uid != null) {
        try {
          _user = await _authService.getUserData();
        } catch (_) {
          _user = null;
        }
      } else {
        _user = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  /// Check initial auth state and wait for it to be determined
  /// This is called from splash screen to ensure we know the auth state
  /// before navigating
  Future<void> checkInitialAuthState() async {
    if (_isInitialized) return;

    // Wait for auth state to be initialized
    final completer = Completer<void>();

    void checkInit() {
      if (_isInitialized) {
        completer.complete();
      }
    }

    // Listen for initialization
    addListener(checkInit);

    // Set a timeout to prevent infinite waiting
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _isInitialized = true;
        notifyListeners();
      },
    );

    removeListener(checkInit);
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUserData() async {
    _user = await _authService.getUserData();
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(name: name, email: email);
      await loadUserData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _isInitialized = true;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
