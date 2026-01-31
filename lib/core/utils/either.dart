/// Functional Either type for error handling
/// Left = Failure, Right = Success
abstract class Either<L, R> {
  const Either();

  bool get isLeft;
  bool get isRight => !isLeft;

  L get left;
  R get right;

  T fold<T>(T Function(L left) fnL, T Function(R right) fnR);

  factory Either.left(L value) = Left<L, R>;
  factory Either.right(R value) = Right<L, R>;
}

class Left<L, R> extends Either<L, R> {
  final L _value;

  const Left(this._value);

  @override
  bool get isLeft => true;

  @override
  L get left => _value;

  @override
  R get right => throw StateError('Cannot get right from Left');

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnL(_value);
}

class Right<L, R> extends Either<L, R> {
  final R _value;

  const Right(this._value);

  @override
  bool get isLeft => false;

  @override
  L get left => throw StateError('Cannot get left from Right');

  @override
  R get right => _value;

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnR(_value);
}
