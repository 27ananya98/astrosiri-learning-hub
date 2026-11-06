import 'package:equatable/equatable.dart';
import '../../../../domain/models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthOtpSent extends AuthState {
  final String identifier;
  final String message;

  const AuthOtpSent({required this.identifier, required this.message});

  @override
  List<Object?> get props => [identifier, message];
}

class Authenticated extends AuthState {
  final User user;
  final bool needsProfileSetup;

  const Authenticated({required this.user, this.needsProfileSetup = false});

  @override
  List<Object?> get props => [user, needsProfileSetup];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class Unauthenticated extends AuthState {
  final String? message;
  const Unauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}
