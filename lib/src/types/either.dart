import 'package:flutter/foundation.dart' show immutable;

/// Simple Either monad implementation for functional error handling
/// Left represents failure/error, Right represents success
sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  L get left => fold<L>(
    (L value) => value,
    (R right) => throw Exception('Illegal use. You should check isLeft before calling'),
  );

  R get right => fold<R>(
    (L left) => throw Exception('Illegal use. You should check isRight before calling'),
    (R value) => value,
  );

  /// Core fold operation - transforms Either to a single value
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR);

  /// Transform the right value, keeping left unchanged
  Either<L, T> map<T>(T Function(R right) fn) {
    return fold(
      Left<L, T>.new,
      (R right) => Right<L, T>(fn(right)),
    );
  }

  /// Transform the left value, keeping right unchanged
  Either<T, R> mapLeft<T>(T Function(L left) fn) {
    return fold(
      (L left) => Left<T, R>(fn(left)),
      Right<T, R>.new,
    );
  }

  /// Chain Either operations (flatMap/bind)
  /// Useful for composing operations that return Either
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) fn) {
    return fold(
      Left<L, T>.new,
      fn,
    );
  }

  /// Get the right value or a default if left
  R getOrElse(R Function() defaultValue) {
    return fold(
      (L _) => defaultValue(),
      (R right) => right,
    );
  }

  /// Get the right value or null if left
  R? getOrNull() {
    return fold(
      (L _) => null,
      (R right) => right,
    );
  }

  /// Get the left value or null if right
  L? getLeftOrNull() {
    return fold(
      (L left) => left,
      (R _) => null,
    );
  }

  /// Return an alternative Either if this is left
  Either<L, R> orElse(Either<L, R> Function() alternative) {
    return fold(
      (L _) => alternative(),
      Right<L, R>.new,
    );
  }

  /// Execute side effect on left value
  Either<L, R> tapLeft(void Function(L left) fn) {
    if (isLeft) fn(left);
    return this;
  }

  /// Execute side effect on right value
  Either<L, R> tap(void Function(R right) fn) {
    if (isRight) fn(right);
    return this;
  }

  /// Swap left and right
  Either<R, L> swap() {
    return fold(
      Right<R, L>.new,
      Left<R, L>.new,
    );
  }
}

@immutable
class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnL(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Left<L, R> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Left($value)';
}

@immutable
class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnR(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Right<L, R> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Right($value)';
}
