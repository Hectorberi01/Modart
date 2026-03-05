import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class AuthState {
  final User? firebaseUser;
  final UserProfile? userProfile;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.firebaseUser,
    this.userProfile,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => firebaseUser != null;

  AuthState copyWith({
    User? firebaseUser,
    UserProfile? userProfile,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return AuthState(
      firebaseUser: clearUser ? null : (firebaseUser ?? this.firebaseUser),
      userProfile: clearProfile ? null : (userProfile ?? this.userProfile),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
