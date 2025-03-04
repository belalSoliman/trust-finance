import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class NeedsSuperAdmin extends AuthState {
  const NeedsSuperAdmin();
}

class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class UnAuthenticated extends AuthState {
  const UnAuthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthActionSuccess extends AuthState {
  final String message;
  const AuthActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
