# Hardware tests

These tests validate behavior against a physical disting NT. They live outside
`test/`, so ordinary `flutter test` runs and release CI do not discover them.

## Prerequisites

1. Connect the disting NT to the computer over USB.
2. Run this checkout of nt_helper and wait for it to synchronize.
3. Enable nt_helper MCP and wait for its status light to turn green.

Run the suite explicitly:

```sh
./tool/run_hardware_tests.sh
```

Set `NT_HELPER_MCP_URL` to target a non-default MCP endpoint. The default is
`http://127.0.0.1:3847/mcp`.

## Specification-aware metadata coverage

`specification_repeat_metadata_hardware_test.dart` records the current preset,
then appends `quan` and `mix1` at representative minimum, middle, and maximum
specification values. For every case it reads the complete metadata shape from
the physical module and compares it exactly with the bundled offline resolver:
parameters and enums, pages and memberships, and output-mode usage. Each
temporary slot is removed in a `finally` block, and the original preset name and
slot layout must be restored before the test passes.

Do not interrupt the process while a temporary algorithm is installed. If that
happens, remove the appended test slot from the current preset before continuing.
