library trestle.orm.lazy_future;

import 'dart:async';

class LazyFuture<T> implements Future<T> {
  final Function _futureFunction;

  LazyFuture(this._futureFunction);

  Future get _future => _futureFunction();

  @override
  Future then(onValue(T value), { Function onError }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future catchError(Function onError,
      {bool test(Object error)}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(action()) {
    return _future.whenComplete(action);
  }

  @override
  Stream<T> asStream() {
    return _future.asStream();
  }

  @override
  Future timeout(Duration timeLimit, {onTimeout()}) {
    return _future.timeout(timeLimit, onTimeout: onTimeout);
  }
}
