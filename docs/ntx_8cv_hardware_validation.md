# NTX-8CV end-of-development hardware validation

Use this checklist with an NTX-8CV, a disting NT, and separate USB connections
for both modules. It records the manual evidence required to accept the
NTX-8CV add-on; it is not a prerequisite for fixture-driven development.

Do not use the **Any** SysEx address (`127`) as the persistent device ID. Do
not enter the bootloader or update firmware during this validation.

## Setup

1. Start the nt_helper build under test on one supported platform.
2. Connect the NTX-8CV and disting NT through their own USB MIDI connections.
3. Open **More options → Add-ons → NTX-8CV**.
4. Record the platform, nt_helper build identity, the selected endpoint names,
   and the chosen persistent SysEx device ID (`0` through `126`). Firmware and
   serial text shown by the device-information exchange are opaque text; record
   them verbatim only when sharing them is appropriate.

## Connection and reads

1. With exactly one input and one output endpoint advertised as `NTX-8CV`,
   confirm that both are preselected. If discovery is unavailable or ambiguous,
   select the input and output manually.
2. Connect. Confirm that the page reaches **Connected** only after device
   information arrives, then records device-confirmed values for ES-5, Channel
   Group, and (when supported) Mode.
3. Change the persistent device ID to another valid value, reconnect, and
   confirm that the chosen ID is retained. Restore the actual device ID before
   continuing.
4. Disconnect the NTX-8CV USB cable, confirm the disconnected state, reconnect
   it, and confirm the endpoints reappear without an automatic connection or
   write.
5. Verify that the disting NT remains independently connected and is not
   rebooted or sent NTX-8CV configuration commands.

## Immediate-write and confirmation behavior

1. Set Channel Group to a different available eight-channel block. Confirm the
   page reports that exact value as device-confirmed only after the readback.
   Confirm its explanation says this does not replace the disting NT's granular
   channel-enable controls.
2. Toggle ES-5. Confirm the changed value becomes device-confirmed only after
   the readback and the page does not say an ES-5 change requires a reboot.
3. With ES-5 enabled, select each Mode in turn: **8x8 CV**, **1x8 32bit
   Audio**, and **2x8 16bit Audio**. For every selection, confirm the mode is
   device-confirmed after readback, ES-5 remains enabled and available, and the
   page reports that an NTX-8CV reboot is required.
4. If Mode is not exposed by the connected firmware, confirm Mode writes stay
   disabled and the page says capability was not evidenced. Record this as a
   firmware/capability finding, not as a proof that the firmware is unsupported.
5. For a recovery check where practical, interrupt a setting write by removing
   the NTX-8CV connection before readback. Confirm the attempted value remains
   pending/failed, the last device-confirmed value remains visible when known,
   and the page labels the actual device state uncertain. Reconnect without
   changing the selected target, confirm no automatic retry occurs, then use
   **Retry send** and confirm matching readback clears the pending state.

## Reboot and refresh

1. With a confirmed Mode change pending a reboot, activate **Reboot NTX-8CV**
   once. Confirm there is no confirmation dialog.
2. Confirm only the selected NTX-8CV restarts. The add-on must reacquire its
   endpoints, validate device information again, then refresh ES-5, Mode, and
   Channel Group.
3. Confirm the refreshed values match the device and that the Mode reboot
   requirement is cleared. Confirm no retained pending/failed setting was sent
   automatically during reconnect or refresh.

## Result record

Record one result for each platform tested:

| Field | Value |
| --- | --- |
| Date and tester | |
| Platform and OS version | |
| nt_helper build/commit | |
| NTX-8CV endpoint names and persistent device ID | |
| Firmware/serial text, if retained | |
| Connection and settings-read result | pass / fail |
| Channel Group result | pass / fail |
| ES-5 result in all three Modes | pass / fail / Mode not evidenced |
| Failed-write, reconnect, and Retry send result | pass / not practical / fail |
| Reboot, revalidation, and refresh result | pass / fail |
| Disting NT remained independently connected | pass / fail |
| Notes and defects | |

A failure or unexpected device behavior is acceptance-blocking until its cause
is recorded and corrected. Preserve the completed record with the release or
project evidence; physical validation is a final acceptance activity, not a
requirement to begin or continue automated development.
