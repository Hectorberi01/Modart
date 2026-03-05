import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthService — Couche Firebase Auth + Firestore
//
// Responsabilités :
//   • Créer / connecter des comptes via Firebase Auth
//   • Persister et lire les profils dans Firestore (/users/{uid})
//   • Valider les codes cabinet (mode Pro) → /cabinet_codes/{code}
//   • Stocker le PIN kids dans Firestore et le vérifier
//   • Stocker l'email kids dans SharedPreferences pour reconnexion PIN
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _kKidsEmail = 'kids_saved_email';
  static const String _kKidsPassword = 'kids_saved_password';

  // ── Accesseurs de base ───────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Inscription ───────────────────────────────────────────────────────────

  /// Crée un compte Firebase Auth et enregistre le profil dans Firestore.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required UserProfile profile,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _saveProfile(credential.user!.uid, profile.copyWith(email: email.trim()));

    // Pour le mode kids : mémoriser l'email pour reconnexion par PIN
    if (profile.profileType == ProfileType.kids) {
      await _saveKidsEmail(email.trim());
    }

    return credential;
  }

  // ── Connexion ─────────────────────────────────────────────────────────────

  /// Connecte un compte existant.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Reset mot de passe ────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Profil Firestore ─────────────────────────────────────────────────────

  Future<void> _saveProfile(String uid, UserProfile profile) async {
    await _db.collection('users').doc(uid).set(
      profile.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Met à jour des champs spécifiques du profil en Firestore.
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {
    await _db.collection('users').doc(uid).update(fields);
  }

  /// Charge le profil depuis Firestore. Retourne null si inexistant.
  Future<UserProfile?> loadProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc.data()!);
  }

  // ── Validation code cabinet (Pro) ────────────────────────────────────────

  /// Vérifie que le code cabinet existe dans Firestore.
  /// Pour le MVP, on accepte aussi le code par défaut "CAB-2026".
  Future<bool> validateCabinetCode(String code) async {
    if (code.trim().toUpperCase() == 'CAB-2026') return true;
    final doc = await _db.collection('cabinet_codes').doc(code.trim().toUpperCase()).get();
    return doc.exists;
  }

  // ── Gestion PIN Kids ─────────────────────────────────────────────────────

  /// Enregistre le PIN kids (4 chiffres) hashé dans Firestore.
  Future<void> saveKidsPin(String uid, String pin) async {
    await _db.collection('users').doc(uid).update({'kidsPin': _hashPin(pin)});
  }

  /// Vérifie le PIN kids saisi contre le hash Firestore.
  Future<bool> verifyKidsPin(String uid, String pin) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    final stored = doc.data()?['kidsPin'] as String?;
    return stored == _hashPin(pin);
  }

  /// Hash simple du PIN pour le stockage (XOR + base64 pour MVP).
  /// En production, utiliser bcrypt ou PBKDF2.
  String _hashPin(String pin) {
    // Simple hash MVP : on préfixe avec un salt fixe et on encode
    final salted = 'SmartSole2026_$pin';
    var hash = 0;
    for (int i = 0; i < salted.length; i++) {
      hash = ((hash << 5) - hash) + salted.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  // ── Persistance email Kids ─────────────────────────────────────────────

  Future<void> _saveKidsEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKidsEmail, email);
  }

  Future<String?> getSavedKidsEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kKidsEmail);
  }

  Future<void> clearKidsEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKidsEmail);
  }

  /// Sauvegarde le mot de passe kids (encodé base64) pour re-auth si session expirée.
  /// MVP uniquement — utiliser un stockage sécurisé (flutter_secure_storage) en production.
  Future<void> saveKidsPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64.encode(password.codeUnits);
    await prefs.setString(_kKidsPassword, encoded);
  }

  Future<String?> getSavedKidsPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_kKidsPassword);
    if (encoded == null) return null;
    try {
      return String.fromCharCodes(base64.decode(encoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearKidsPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKidsPassword);
  }

  // ── Traduction des codes d'erreur Firebase ───────────────────────────────

  static String translateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé. Connectez-vous.';
      case 'weak-password':
        return 'Mot de passe trop court (6 caractères minimum).';
      case 'invalid-email':
        return 'Format d\'email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'network-request-failed':
        return 'Pas de connexion réseau. Vérifiez votre connexion.';
      case 'operation-not-allowed':
        return 'Méthode de connexion désactivée. Contactez le support.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}
