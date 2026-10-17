import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/chat/services/system_prompt.dart';

void main() {
  test('bakes durable user setup rules into the stable prompt prefix', () {
    final prompt = distingNtSystemPrompt();

    expect(prompt, contains('`yymmdd-[description]`'));
    expect(prompt, contains('Never reuse a preset name'));
    expect(prompt, contains('USB Filesystem mode'));
    expect(prompt, contains('`midi_channel: 14`'));
    expect(prompt, contains("Use its GUID and `algorithm_info`"));
  });

  test('includes remote operating guidance in the stable prefix', () {
    final prompt = distingNtSystemPrompt(
      memoryContent: 'session-specific memory',
    );
    final remoteStart = prompt.indexOf('## Remote Control');
    expect(remoteStart, greaterThanOrEqualTo(0));
    expect(remoteStart, lessThan(prompt.indexOf('## Memory\n')));
    final remote = prompt.substring(
      remoteStart,
      prompt.indexOf('## Response Style'),
    );
    expect(remote, contains('`remote_state({})` and `show_screen({})`'));
    expect(remote, contains('`show_screen` takes no arguments'));
    expect(remote, contains('Use `remote_control` for menu navigation'));
    expect(
      remote,
      contains('Reserve `set_display_mode` for an explicit user request'),
    );
    expect(remote, contains('encoder presses = 7–8'));
    expect(remote, contains('encoders left/right = 0/1'));
    expect(remote, contains('pots left/center/right = 0/1/2'));
    expect(remote, contains('primary encoder are configurable'));
    expect(remote, contains('holds never persist across calls'));
    expect(
      remote,
      contains('Require authorization before destructive actions'),
    );
    expect(remote, contains('not acknowledged hardware execution'));
    expect(remote, contains('stop on unknown release'));
  });
}
