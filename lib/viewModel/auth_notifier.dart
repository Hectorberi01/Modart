import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../state/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service = AuthService();

  AuthNotifier() : super(const AuthState()) {
    _service.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    UserProfile? profile;
    if (user != null) {
      profile = await _service.loadProfile(user.uid);
    }
    state = state.copyWith(
      firebaseUser: user,
      userProfile: profile,
      isInitialized: true,
      clearUser: user == null,
      clearProfile: user == null,
    );
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _service.signIn(email: email, password: password);
      final profile = await _service.loadProfile(credential.user!.uid);
      state = state.copyWith(
        firebaseUser: credential.user,
        userProfile: profile,
        isLoading: false,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AuthService.translateError(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Une erreur inattendue est survenue.');
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _service.signUp(email: email, password: password, profile: profile);
      state = state.copyWith(
        firebaseUser: credential.user,
        userProfile: profile.copyWith(email: email),
        isLoading: false,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AuthService.translateError(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Une erreur inattendue est survenue.');
      return false;
    }
  }

  Future<bool> signUpKids({
    required String email,
    required String password,
    required String pin,
    required UserProfile profile,
  }) async {
    final ok = await signUp(email: email, password: password, profile: profile);
    if (!ok || state.firebaseUser == null) return false;
    try {
      await _service.saveKidsPin(state.firebaseUser!.uid, pin);
      await _service.saveKidsPassword(password);
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Compte créé, mais erreur lors de l\'enregistrement du PIN.');
      return false;
    }
  }

  Future<bool> verifyKidsPin(String pin) async {
    if (state.firebaseUser == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      final valid = await _service.verifyKidsPin(state.firebaseUser!.uid, pin);
      if (!valid) {
        state = state.copyWith(isLoading: false, errorMessage: 'Code PIN incorrect.');
      } else {
        state = state.copyWith(isLoading: false, clearError: true);
      }
      return valid;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Erreur lors de la vérification du PIN.');
      return false;
    }
  }

  Future<bool> signInWithKidsPin({required String pin}) async {
    if (state.firebaseUser != null) {
      return verifyKidsPin(pin);
    }
    final email = await _service.getSavedKidsEmail();
    final password = await _service.getSavedKidsPassword();
    if (email == null || password == null) {
      state = state.copyWith(errorMessage: 'Session expirée. Veuillez recréer votre compte.');
      return false;
    }
    final ok = await signIn(email, password);
    if (!ok) return false;
    return verifyKidsPin(pin);
  }

  Future<bool> validateCabinetCode(String code) => _service.validateCabinetCode(code);

  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    if (state.firebaseUser == null || state.userProfile == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateProfile(state.firebaseUser!.uid, fields);
      final updated = UserProfile.fromFirestore({
        ...state.userProfile!.toFirestore(),
        ...fields,
      });
      state = state.copyWith(userProfile: updated, isLoading: false, clearError: true);
      return true;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Erreur lors de la mise à jour du profil.');
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.sendPasswordReset(email);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AuthService.translateError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = state.copyWith(clearUser: true, clearProfile: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
