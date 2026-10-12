/// Typed remote inputs. Turn indices are distinct from the nine push indices.
sealed class RemoteAction {
  const RemoteAction(this.index);

  const factory RemoteAction.push(int index) = RemotePush;
  const factory RemoteAction.release(int index) = RemoteRelease;
  const factory RemoteAction.encoderTurn(int index, int delta) =
      RemoteEncoderTurn;
  const factory RemoteAction.potTurn(int index, int value) = RemotePotTurn;

  final int index;

  void validate() {
    final maximum = switch (this) {
      RemotePush() || RemoteRelease() => 8,
      RemoteEncoderTurn() => 1,
      RemotePotTurn() => 2,
    };
    if (index < 0 || index > maximum) {
      throw RangeError.range(index, 0, maximum, 'index');
    }
    if (this case RemotePotTurn(:final value)) {
      if (value < 0 || value > 4095) {
        throw RangeError.range(value, 0, 4095, 'value');
      }
    }
  }

  /// Splits relative movement without changing its total or order.
  /// Validation happens before yielding any command.
  Iterable<RemoteAction> get wireActions sync* {
    validate();
    if (this case RemoteEncoderTurn(:final delta)) {
      var remaining = delta;
      while (remaining != 0) {
        final step = remaining.clamp(-64, 63);
        yield RemoteEncoderTurn(index, step);
        remaining -= step;
      }
    } else {
      yield this;
    }
  }
}

final class RemotePush extends RemoteAction {
  const RemotePush(super.index);
}

final class RemoteRelease extends RemoteAction {
  const RemoteRelease(super.index);
}

final class RemoteEncoderTurn extends RemoteAction {
  const RemoteEncoderTurn(super.index, this.delta);
  final int delta;
}

final class RemotePotTurn extends RemoteAction {
  const RemotePotTurn(super.index, this.value);
  final int value;
}
