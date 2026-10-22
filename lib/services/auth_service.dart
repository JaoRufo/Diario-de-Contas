import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<User?>? _authSubscription;

  User? _currentUser;
  bool _initialized = false;
  bool _isBusy = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  String? get uid => _currentUser?.uid;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  bool get _supportsGoogleSignIn {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }

  Future<void> initialize() async {
    if (_initialized) return;

    _currentUser = _firebaseAuth.currentUser;
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });

    if (_supportsGoogleSignIn) {
      await _googleSignIn.initialize();
    }
    _initialized = true;
  }

  Future<User?> signInWithGoogle() async {
    if (!_supportsGoogleSignIn) {
      _errorMessage = 'Login com Google não está disponível nesta plataforma.';
      notifyListeners();
      return null;
    }

    _setBusy(true);
    _errorMessage = null;
    try {
      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        _errorMessage = 'O Google não forneceu uma credencial válida.';
        return null;
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _firebaseAuth.signInWithCredential(credential);
      _currentUser = result.user;
      return result.user;
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled &&
          error.code != GoogleSignInExceptionCode.interrupted) {
        _errorMessage = 'Não foi possível entrar com o Google.';
      }
      return null;
    } on FirebaseAuthException {
      _errorMessage = 'Não foi possível autenticar no Firebase.';
      return null;
    } catch (_) {
      _errorMessage = 'Não foi possível concluir o login com o Google.';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    _setBusy(true);
    _errorMessage = null;
    try {
      await _firebaseAuth.signOut();
      if (_supportsGoogleSignIn) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      _errorMessage = 'Não foi possível sair da conta.';
    } finally {
      _setBusy(false);
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
