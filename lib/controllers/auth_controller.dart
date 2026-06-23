import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  auth.FirebaseAuth? _auth;
  bool _isLoading = false;
  String? _errorMessage;

  // Mock State Variables
  String? _mockUid;
  String? _mockEmail;

  AuthController() {
    try {
      _auth = auth.FirebaseAuth.instance;
      _auth!.authStateChanges().listen((auth.User? user) {
        notifyListeners();
      });
    } catch (e) {
      // Firebase not initialized, fallback to mock mode
      FirebaseService.initMock();
      _mockUid = FirebaseService.loadedSessionUid;
      _mockEmail = FirebaseService.loadedSessionEmail;
    }
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get currentUserId {
    if (FirebaseService.useMock) {
      return _mockUid;
    }
    return _auth?.currentUser?.uid;
  }

  String? get currentUserEmail {
    if (FirebaseService.useMock) {
      return _mockEmail;
    }
    return _auth?.currentUser?.email;
  }

  bool get isAuthenticated => currentUserId != null;

  /// Trigger mock mode manually for testing.
  void enableMockMode() {
    FirebaseService.initMock();
    _mockUid = 'mock_uid_123';
    _mockEmail = 'rehan@finsim.com';
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('mock_session_uid', 'mock_uid_123');
      prefs.setString('mock_session_email', 'rehan@finsim.com');
    });
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (FirebaseService.useMock || _auth == null) {
        await Future.delayed(const Duration(milliseconds: 600));
        // Simple mock credentials check: use default UID for demo, else create unique derived UID
        if (email == 'rehan@finsim.com') {
          _mockUid = 'mock_uid_123';
        } else {
          _mockUid = 'mock_uid_${email.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        }
        _mockEmail = email;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mock_session_uid', _mockUid!);
        await prefs.setString('mock_session_email', _mockEmail!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(RegExp(r'\[.*\]'), '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (FirebaseService.useMock || _auth == null) {
        await Future.delayed(const Duration(milliseconds: 600));
        // Generate a unique derived mock UID based on the email
        _mockUid = 'mock_uid_${email.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        _mockEmail = email;

        // Add mock profile to mock DB
        final firebaseService = FirebaseService();
        await firebaseService.createUserProfile(UserModel(
          uid: _mockUid!,
          email: email,
          monthlySalary: 0.0,
          profession: '',
        ));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mock_session_uid', _mockUid!);
        await prefs.setString('mock_session_email', _mockEmail!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      final credential = await _auth!.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final firebaseService = FirebaseService();
        await firebaseService.createUserProfile(UserModel(
          uid: credential.user!.uid,
          email: email,
          monthlySalary: 0.0,
          profession: '',
        ));
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(RegExp(r'\[.*\]'), '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    if (FirebaseService.useMock || _auth == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockUid = null;
      _mockEmail = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mock_session_uid');
      await prefs.remove('mock_session_email');

      _isLoading = false;
      notifyListeners();
      return;
    }

    await _auth!.signOut();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateCredentials(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (FirebaseService.useMock || _auth == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _mockEmail = email;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mock_session_email', _mockEmail!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      final user = _auth!.currentUser;
      if (user != null) {
        if (email.isNotEmpty && email != user.email) {
          await user.verifyBeforeUpdateEmail(email);
        }
        if (password.isNotEmpty) {
          await user.updatePassword(password);
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(RegExp(r'\[.*\]'), '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
