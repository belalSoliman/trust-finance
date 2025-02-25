import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repos/auth_repo.dart';
import '../../models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial());

  Future<void> signIn(String email, String password) async {
    try {
      emit(const AuthLoading());
      final user = await _authRepository.signIn(email, password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkInitialSetup() async {
    try {
      emit(const AuthLoading());

      final hasSuperAdmin = await _authRepository.checkSuperAdminExists();

      if (!hasSuperAdmin) {
        emit(const NeedsSuperAdmin());
      } else {
        // Check if user is already logged in
        _authRepository.currentUser.listen(
          (user) {
            if (user != null) {
              emit(Authenticated(user));
            } else {
              emit(const UnAuthenticated());
            }
          },
          onError: (error) => emit(AuthError(error.toString())),
        );
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      emit(const AuthLoading());
      await _authRepository.signOut();
      emit(const UnAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    if (state is! Authenticated) {
      emit(const AuthError('Must be logged in to create users'));
      return;
    }

    try {
      emit(const AuthLoading());
      await _authRepository.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
        currentUser: (state as Authenticated).user,
      );
      emit(const AuthActionSuccess('User created successfully'));
      emit(Authenticated(
          (state as Authenticated).user)); // Restore previous state
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  bool get isSuperAdmin {
    return state is Authenticated &&
        (state as Authenticated).user.role == UserRole.superAdmin;
  }

  void checkCurrentUser() {
    _authRepository.currentUser.listen(
      (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const UnAuthenticated());
        }
      },
      onError: (error) => emit(AuthError(error.toString())),
    );
  }
}
