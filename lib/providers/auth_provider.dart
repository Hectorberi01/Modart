import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthProvider — État global de l'authentification
//
// Expose :
//   • isAuthenticated / firebaseUser / userProfile
//   • isLoading / errorMessage
//   • Méthodes signIn, signUp, signOut, sendPasswordReset
//   • Méthodes kids : verifyPin, signUpWithPin
//
// Écoute authStateChanges de Firebase pour la persistance automatique.
// ─────────────────────────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  User? _firebaseUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider() {
    // Écoute les changements d'état Firebase (login persistant, déconnexion)
    _service.authStateChanges.listen(_onAuthStateChanged);
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  User? get firebaseUser => _firebaseUser;
  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// True dès que le premier événement authStateChanges a été traité (profil chargé).
  /// Utiliser pour éviter la race condition dans _AuthGate.
  bool get isInitialized => _isInitialized;

  // ── Listener Firebase ─────────────────────────────────────────────────────

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _userProfile = await _service.loadProfile(user.uid);
    } else {
      _userProfile = null;
    }
    _isInitialized = true; // profil chargé → _AuthGate peut naviguer
    notifyListeners();
  }

  // ── Connexion ─────────────────────────────────────────────────────────────

  /// Retourne true en cas de succès, false sinon (errorMessage renseigné).
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final credential = await _service.signIn(email: email, password: password);
      _userProfile = await _service.loadProfile(credential.user!.uid);
      _setError(null);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.translateError(e));
      return false;
    } catch (_) {
      _setError('Une erreur inattendue est survenue.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Inscription ───────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    _setLoading(true);
    try {
      final credential = await _service.signUp(
        email: email,
        password: password,
        profile: profile,
      );
      _userProfile = profile.copyWith(email: email);
      _firebaseUser = credential.user;
      _setError(null);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.translateError(e));
      return false;
    } catch (_) {
      _setError('Une erreur inattendue est survenue.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Inscription Kids avec PIN ─────────────────────────────────────────────

  /// Crée le compte kids (email + password) et enregistre le PIN dans Firestore.
  Future<bool> signUpKids({
    required String email,
    required String password,
    required String pin,
    required UserProfile profile,
  }) async {
    final ok = await signUp(email: email, password: password, profile: profile);
    if (!ok || _firebaseUser == null) return false;
    try {
      await _service.saveKidsPin(_firebaseUser!.uid, pin);
      // Sauvegarder le password pour re-auth silencieuse si session expirée
      await _service.saveKidsPassword(password);
      return true;
    } catch (_) {
      _setError('Compte créé, mais erreur lors de l\'enregistrement du PIN.');
      return false;
    }
  }

  // ── Connexion Kids via PIN ────────────────────────────────────────────────

  /// Vérifie le PIN d'un utilisateur kids déjà connecté.
  Future<bool> verifyKidsPin(String pin) async {
    if (_firebaseUser == null) return false;
    _setLoading(true);
    try {
      final valid = await _service.verifyKidsPin(_firebaseUser!.uid, pin);
      if (!valid) _setError('Code PIN incorrect.');
      _setLoading(false);
      return valid;
    } catch (_) {
      _setError('Erreur lors de la vérification du PIN.');
      _setLoading(false);
      return false;
    }
  }

  /// Connexion kids via PIN.
  /// - Si session Firebase active  → vérifie le PIN directement.
  /// - Si session expirée          → re-authentifie silencieusement puis vérifie le PIN.
  Future<bool> signInWithKidsPin({required String pin}) async {
    if (_firebaseUser != null) {
      return verifyKidsPin(pin);
    }

    // Session expirée : re-auth silencieuse avec credentials sauvegardés
    final email = await _service.getSavedKidsEmail();
    final password = await _service.getSavedKidsPassword();
    if (email == null || password == null) {
      _setError('Session expirée. Veuillez recréer votre compte.');
      return false;
    }

    final ok = await signIn(email, password);
    if (!ok) return false;
    return verifyKidsPin(pin);
  }

  // ── Validation code cabinet (Pro) ────────────────────────────────────────

  Future<bool> validateCabinetCode(String code) =>
      _service.validateCabinetCode(code);
  // ── Mise à jour profil ────────────────────────────────────────────────────

  /// Met à jour des champs du profil en Firestore et en mémoire locale.
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    if (_firebaseUser == null || _userProfile == null) return false;
    _setLoading(true);
    try {
      await _service.updateProfile(_firebaseUser!.uid, fields);
      // Merge en mémoire pour éviter un reload Firestore complet
      _userProfile = UserProfile.fromFirestore({
        ..._userProfile!.toFirestore(),
        ...fields,
      });
      _setError(null);
      notifyListeners();
      return true;
    } catch (_) {
      _setError('Erreur lors de la mise à jour du profil.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Réinitialisation mot de passe ─────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _service.sendPasswordReset(email);
      _setError(null);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthService.translateError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _service.signOut();
    _userProfile = null;
    _firebaseUser = null;
    notifyListeners();
  }

  // ── Helpers d'état internes ───────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
