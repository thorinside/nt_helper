# NTX-8CV SysEx protocol foundation

`lib/domain/ntx_8cv/ntx_8cv_sysex.dart` is the dedicated NTX-8CV codec and
single-device session. It is deliberately separate from the disting NT SysEx
implementation: NTX-8CV frames use product byte `0x6A`, while the disting NT
uses `0x6D`.

## Documented frame forms

All frames start with `F0 00 21 27 6A <device-id>` and end with `F7`.

| Operation | Direction | Body after device ID |
| --- | --- | --- |
| Device information | host to device | `22` |
| Device information response | device to host | `32 <NUL-terminated opaque ASCII fields>` |
| Read setting | host to device | `31 <setting-id>` |
| Setting response | device to host | `31 <setting-id> <value>` |
| Write setting | host to device | `32 <setting-id> <value>` |
| Reboot | host to device | `7F` |

The protocol defines neither a checksum nor a setting-write acknowledgement.
`Ntx8cvSession.writeAndConfirmSetting` therefore writes, reads the same
setting, and succeeds only when the returned setting ID and value match. It
never retries automatically. Session timeout is an injected implementation
choice, not a manufacturer protocol claim.

## Fixture-driven development

`test/fixtures/ntx_8cv_sysex_fixtures.dart` holds deterministic frames used by
`test/domain/ntx_8cv/ntx_8cv_sysex_test.dart`. The fixture firmware and serial
strings are opaque sample text; they do not assert a device-version grammar or
represent captured hardware data. The suite covers framing, response parsing,
malformed input, selected-device matching, matching and mismatched readback,
and a configurable no-response timeout without requiring an NTX-8CV.

Physical hardware is not a prerequisite for feature development. When a task
would materially benefit from an on-device result, request temporary NTX-8CV
access from the product owner and retain the resulting validation evidence.
