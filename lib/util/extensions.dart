extension LetExtension<T> on T? {
  void let(void Function(T) block) {
    final self = this;
    if (self != null) {
      block(self);
    }
  }
}