import 'package:attendanceweb/Features/Models/client.dart';
import 'package:attendanceweb/Services/Database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Stream provider for authentication state
final authStateProvider = StreamProvider<Client?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.auth;
});

final authStreamProvider = StreamProvider<Client?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.auth;
});

// State for the current client
class AuthState {
  final Client? currentClient;
  final bool isLoading;
  final String? error;

  AuthState({
    this.currentClient,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    Client? currentClient,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      currentClient: currentClient ?? this.currentClient,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// StateNotifier to replace AuthNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  void setUser(Client client) {
    state = state.copyWith(currentClient: client);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for the AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  // Convert Firebase User to Client model
  Client? _userFromFirebaseUser(User? user, bool signUp) {
    return user != null
        ? Client(
            uid: user.uid,
            clientName: '',
            clientEmail: user.email!,
            status: signUp ? 'Pending' : 'Verified',
            role: '',
          )
        : null;
  }

  // UserAuth stream to listen to auth changes
  Stream<Client?> get auth {
    return _auth
        .authStateChanges()
        .map((user) => _userFromFirebaseUser(user, false));
  }

  // Register with email & password
  Future<Client?> registerWithEmailAndPassword(
      String name, String email, String password, String role, WidgetRef ref) async {
    try {
      ref.read(authNotifierProvider.notifier).setLoading(true);
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User user = result.user!;
      
      // Create and save client data
      final client = Client(
        uid: user.uid,
        clientName: name,
        clientEmail: user.email!,
        status: 'Pending',
        role: role,
      );
      
      await Database.saveClientData(client);
      ref.read(authNotifierProvider.notifier).setLoading(false);
      return client;
    } catch (e) {
      ref.read(authNotifierProvider.notifier).setLoading(false);
      ref.read(authNotifierProvider.notifier).setError(e.toString());
      return null;
    }
  }

  // Sign in with email & password
Future<Client?> signInWithEmailAndPassword(
    String email, String password, WidgetRef ref) async {
  try {
    ref.read(authNotifierProvider.notifier).setLoading(true);
    
    // First authenticate with Firebase
    UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    
    // Then get client data from database
    final clientData = await Database.getClientData(email);
    ref.read(authNotifierProvider.notifier).setUser(clientData);
    
    // Verify role
    if (clientData.role != 'admin') {
      await _auth.signOut(); // Sign out if not admin
      throw Exception('Only admin users can access this dashboard');
    }
    
    ref.read(authNotifierProvider.notifier).setLoading(false);
    return clientData;
  } catch (e) {
    ref.read(authNotifierProvider.notifier).setLoading(false);
    ref.read(authNotifierProvider.notifier).setError(e.toString());
    return null;
  }
}

  // Sign out Method
  Future<void> signOut(WidgetRef ref) async {
    try {
      ref.read(authNotifierProvider.notifier).setLoading(true);
      await _auth.signOut();
      ref.read(authNotifierProvider.notifier).setLoading(false);
    } catch (e) {
      ref.read(authNotifierProvider.notifier).setLoading(false);
      ref.read(authNotifierProvider.notifier).setError(e.toString());
    }
  }
}