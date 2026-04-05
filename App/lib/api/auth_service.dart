import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  
  bool _isGoogleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _isGoogleSignInInitialized = true;
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    if (AppConfig.useMockData) return null; // Handled by mock logic
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> registerWithEmail(String email, String password) async {
    if (AppConfig.useMockData) return null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> loginWithGoogle() async {
    if (AppConfig.useMockData) return null;
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final authz = await googleUser.authorizationClient.authorizationForScopes(['email', 'profile'])
                 ?? await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authz.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    if (AppConfig.useMockData) return;
    await _auth.signOut();
    await _ensureGoogleSignInInitialized();
    await GoogleSignIn.instance.signOut();
  }

  User? getCurrentFirebaseUser() {
    if (AppConfig.useMockData) return null;
    return _auth.currentUser;
  }
}
