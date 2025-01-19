extension LetExtension<T> on T? {
  void let(void Function(T) block) {
    final self = this;
    if (self != null) {
      block(self);
    }
  }
}

extension MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) transform) sync* {
    var index = 0;
    for (final element in this) {
      yield transform(index++, element);
    }
  }
}