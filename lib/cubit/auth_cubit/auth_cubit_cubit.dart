import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trust_finiance/cubit/auth_cubit/auth_cubit_state.dart';
import 'package:trust_finiance/repos/auth_repos.dart';
import 'package:trust_finiance/utils/user_role.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial());

  void checkAuth() {
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

  Future<void> signIn(String email, String password) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signIn(email, password);
      emit(Authenticated(user));
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

    emit(const AuthLoading());
    try {
      await _authRepository.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
        currentUser: (state as Authenticated).user,
      );
      emit(Authenticated((state as Authenticated).user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _authRepository.signOut();
      emit(const UnAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  bool get isSuperAdmin {
    return state is Authenticated &&
        (state as Authenticated).user.role == UserRole.superAdmin;
  }
}
