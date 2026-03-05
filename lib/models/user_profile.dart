// ─────────────────────────────────────────────────────────────────────────────
// UserProfile — Profil utilisateur SmartSole
//
// 3 types : Urban Actif, Kids (parent+enfant), Pro Santé.
// Le type détermine la palette, les indicateurs et les fonctionnalités.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// Genre utilisateur
enum UserGender { male, female }

/// Profil utilisateur SmartSole.
enum ProfileType { urban, kids, pro }

@immutable
class UserProfile {
  const UserProfile({
    this.id,
    required this.email,
    required this.profileType,
    this.gender,
    this.displayName,
    this.shoeSize,
    this.weightKg,
    this.heightCm,
    this.childProfile,
    this.isOnboardingComplete = false,
    this.isDarkMode = true,
    this.isOfflineMode = false,
    this.consentCloud = false,
    this.consentAnalytics = false,
    this.consentPush = false,
    this.initialPainScore,
  });

  final int? id;
  final String email;
  final ProfileType profileType;
  final UserGender? gender;
  final String? displayName;
  final double? shoeSize;
  final double? weightKg;
  final double? heightCm;

  /// Profil enfant (Persona 2 uniquement).
  final ChildProfile? childProfile;

  /// Onboarding complété ?
  final bool isOnboardingComplete;

  /// Préférence dark mode (défaut : true).
  final bool isDarkMode;

  /// Mode offline (défaut : false).
  final bool isOfflineMode;

  /// Consentements RGPD.
  final bool consentCloud;
  final bool consentAnalytics;
  final bool consentPush;

  /// Score de douleur initial (J0) — renseigné à l'onboarding.
  final int? initialPainScore;

  /// Helpers persona.
  bool get isUrban => profileType == ProfileType.urban;
  bool get isKids => profileType == ProfileType.kids;
  bool get isPro => profileType == ProfileType.pro;

  // ── Firestore sérialisation ─────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'profileType': profileType.name, // 'urban' | 'kids' | 'pro'
      if (gender != null) 'gender': gender!.name,
      if (displayName != null) 'displayName': displayName,
      if (shoeSize != null) 'shoeSize': shoeSize,
      if (weightKg != null) 'weightKg': weightKg,
      if (heightCm != null) 'heightCm': heightCm,
      if (childProfile != null) 'childProfile': childProfile!.toFirestore(),
      'isOnboardingComplete': isOnboardingComplete,
      'isDarkMode': isDarkMode,
      'isOfflineMode': isOfflineMode,
      'consentCloud': consentCloud,
      'consentAnalytics': consentAnalytics,
      'consentPush': consentPush,
      if (initialPainScore != null) 'initialPainScore': initialPainScore,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      email: data['email'] as String? ?? '',
      profileType: ProfileType.values.firstWhere(
        (e) => e.name == data['profileType'],
        orElse: () => ProfileType.urban,
      ),
      gender: data['gender'] != null
          ? UserGender.values.firstWhere(
              (e) => e.name == data['gender'],
              orElse: () => UserGender.male,
            )
          : null,
      displayName: data['displayName'] as String?,
      shoeSize: (data['shoeSize'] as num?)?.toDouble(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      childProfile: data['childProfile'] != null
          ? ChildProfile.fromFirestore(data['childProfile'] as Map<String, dynamic>)
          : null,
      isOnboardingComplete: data['isOnboardingComplete'] as bool? ?? false,
      isDarkMode: data['isDarkMode'] as bool? ?? true,
      isOfflineMode: data['isOfflineMode'] as bool? ?? false,
      consentCloud: data['consentCloud'] as bool? ?? false,
      consentAnalytics: data['consentAnalytics'] as bool? ?? false,
      consentPush: data['consentPush'] as bool? ?? false,
      initialPainScore: data['initialPainScore'] as int?,
    );
  }

  UserProfile copyWith({
    int? id,
    String? email,
    ProfileType? profileType,
    UserGender? gender,
    String? displayName,
    double? shoeSize,
    double? weightKg,
    double? heightCm,
    ChildProfile? childProfile,
    bool? isOnboardingComplete,
    bool? isDarkMode,
    bool? isOfflineMode,
    bool? consentCloud,
    bool? consentAnalytics,
    bool? consentPush,
    int? initialPainScore,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      profileType: profileType ?? this.profileType,
      gender: gender ?? this.gender,
      displayName: displayName ?? this.displayName,
      shoeSize: shoeSize ?? this.shoeSize,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      childProfile: childProfile ?? this.childProfile,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      consentCloud: consentCloud ?? this.consentCloud,
      consentAnalytics: consentAnalytics ?? this.consentAnalytics,
      consentPush: consentPush ?? this.consentPush,
      initialPainScore: initialPainScore ?? this.initialPainScore,
    );
  }
}

/// Profil enfant (pour Persona 2 — Parent).
@immutable
class ChildProfile {
  const ChildProfile({
    this.id,
    required this.nickname,
    required this.birthMonth,
    required this.birthYear,
    this.heightCm,
  });

  final int? id;

  /// Prénom de l'enfant.
  final String nickname;

  /// Mois de naissance.
  final int birthMonth;

  /// Année de naissance.
  final int birthYear;

  /// Taille en cm (optionnel).
  final double? heightCm;

  /// Âge en mois calculé.
  int get ageMonths {
    final now = DateTime.now();
    return (now.year - birthYear) * 12 + (now.month - birthMonth);
  }

  /// Tranche d'âge pour les normes IMM.
  String get ageGroup {
    final months = ageMonths;
    if (months < 48) return '3-4 ans';
    if (months < 72) return '5-6 ans';
    if (months < 120) return '7-10 ans';
    return '> 10 ans';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nickname': nickname,
      'birthMonth': birthMonth,
      'birthYear': birthYear,
      if (heightCm != null) 'heightCm': heightCm,
    };
  }

  factory ChildProfile.fromFirestore(Map<String, dynamic> data) {
    return ChildProfile(
      nickname: data['nickname'] as String? ?? '',
      birthMonth: data['birthMonth'] as int? ?? 1,
      birthYear: data['birthYear'] as int? ?? 2020,
      heightCm: (data['heightCm'] as num?)?.toDouble(),
    );
  }
}
