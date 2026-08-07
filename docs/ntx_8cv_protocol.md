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

## Released audio-channel enable settings

The released Expert Sleepers NTX-8CV configuration tool available for this
follow-up identifies **Enable audio channel** controls 1 through 8 as boolean
settings `0x04` through `0x0B`, in ascending channel order. Each setting uses
`0` for disabled and `1` for enabled. This evidence is distinct from Channel
Group (`0x00`), which selects an eight-channel block and is not a per-channel
enable flag.

nt_helper reads all eight audio-channel settings after identity validation and
on a user-requested settings refresh. The controls are applicable only when a
device-confirmed Mode is **1x8 32bit Audio** or **2x8 16bit Audio**; in **8x8
CV** mode they remain visible but unavailable with an explanation. A write is
still confirmed only by a matching read of the same channel setting.

The setting IDs and boolean encoding were audited against the local released
configuration-tool source, `ntx8cv_config_tool.html`: its Settings panel
creates the eight controls with `settings.push([..., 4+i, setBool])`, labels
them “Enable audio channel”, reads them with `0x31`, and writes them with
`0x32`. They are also captured in the checked-in deterministic fixtures. No
Channel Group value, inferred lane count, or disting NT algorithm parameter is
used as a substitute.

## Fixture-driven development

`test/fixtures/ntx_8cv_sysex_fixtures.dart` holds deterministic frames used by
`test/domain/ntx_8cv/ntx_8cv_sysex_test.dart`. The fixture firmware and serial
strings are opaque sample text; they do not assert a device-version grammar or
represent captured hardware data. The suite covers framing, response parsing,
malformed input, selected-device matching, matching and mismatched readback,
and a configurable no-response timeout without requiring an NTX-8CV. The
fixtures also cover the released first audio-channel enable setting; cubit
coverage exercises all eight setting IDs, individual writes, mismatched
readback, timeout/uncertain state, refresh, reconnect, and reboot reacquisition.

Physical hardware is not a prerequisite for feature development. When a task
would materially benefit from an on-device result, request temporary NTX-8CV
access from the product owner and retain the resulting validation evidence.
