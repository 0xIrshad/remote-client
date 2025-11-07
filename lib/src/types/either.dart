/// Simple Either monad implementation for functional error handling
/// Left represents failure/error, Right represents success
sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  L get left => fold<L>(
    (value) => value,
    (right) =>
        throw Exception('Illegal use. You should check isLeft before calling'),
  );

  R get right => fold<R>(
    (left) =>
        throw Exception('Illegal use. You should check isRight before calling'),
    (value) => value,
  );

  T fold<T>(T Function(L left) fnL, T Function(R right) fnR);
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnL(value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnR(value);
}
