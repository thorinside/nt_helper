#!/usr/bin/env python3
"""
Show different USB enumeration scenarios for disting NT
"""

import usb.core
import usb.util

VENDOR_ID = 0x3773
PRODUCT_ID = 0x0001

def main():
    dev = usb.core.find(idVendor=VENDOR_ID, idProduct=PRODUCT_ID)
    if dev is None:
        print(f"Device not found")
        return

    print(f"Found: {dev.manufacturer} {dev.product}\n")

    cfg = dev[0]

    # Scenario 1: Only default alternate settings (alt 0)
    print("="*80)
    print("SCENARIO 1: Firmware only looks at default alternate settings (alt 0)")
    print("="*80)
    endpoints_alt0 = []
    for intf in cfg:
        if intf.bAlternateSetting == 0 and intf.bNumEndpoints > 0:
            for ep in intf:
                ep_addr = ep.bEndpointAddress
                ep_num = ep_addr & 0x0F
                direction = "IN " if ep_addr & 0x80 else "OUT"
                ep_type = get_endpoint_type(ep.bmAttributes & 0x03)
                midi = intf.bInterfaceClass == 1 and intf.bInterfaceSubClass == 3
                endpoints_alt0.append({
                    'intf': intf.bInterfaceNumber,
                    'ep_num': ep_num,
                    'addr': ep_addr,
                    'dir': direction.strip(),
                    'type': ep_type,
                    'midi': midi
                })

    for i, ep in enumerate(endpoints_alt0, 1):
        marker = " <- MIDI" if ep['midi'] else ""
        print(f"{i}. EP{ep['ep_num']} (0x{ep['addr']:02x}) {ep['dir']:3s} {ep['type']:12s} Intf {ep['intf']}{marker}")

    if endpoints_alt0:
        midi_positions = [i+1 for i, ep in enumerate(endpoints_alt0) if ep['midi']]
        if midi_positions:
            print(f"\nMIDI at positions: {midi_positions}")
            print(f"Searching first 6: {'FOUND' if all(p <= 6 for p in midi_positions) else 'MISSED'}")
        else:
            print("\nMIDI: NOT FOUND")
    else:
        print("NO ENDPOINTS")

    # Scenario 2: All endpoints across all alternate settings
    print("\n" + "="*80)
    print("SCENARIO 2: All endpoints (including alternate settings)")
    print("="*80)
    endpoints_all = []
    for intf in cfg:
        if intf.bNumEndpoints > 0:
            for ep in intf:
                ep_addr = ep.bEndpointAddress
                ep_num = ep_addr & 0x0F
                direction = "IN " if ep_addr & 0x80 else "OUT"
                ep_type = get_endpoint_type(ep.bmAttributes & 0x03)
                midi = intf.bInterfaceClass == 1 and intf.bInterfaceSubClass == 3
                endpoints_all.append({
                    'intf': intf.bInterfaceNumber,
                    'alt': intf.bAlternateSetting,
                    'ep_num': ep_num,
                    'addr': ep_addr,
                    'dir': direction.strip(),
                    'type': ep_type,
                    'midi': midi
                })

    for i, ep in enumerate(endpoints_all, 1):
        marker = " <- MIDI" if ep['midi'] else ""
        print(f"{i}. EP{ep['ep_num']} (0x{ep['addr']:02x}) {ep['dir']:3s} {ep['type']:12s} Intf {ep['intf']}.{ep['alt']}{marker}")

    midi_positions = [i+1 for i, ep in enumerate(endpoints_all) if ep['midi']]
    if midi_positions:
        print(f"\nMIDI at positions: {midi_positions}")
        print(f"Searching first 6: {'FOUND' if all(p <= 6 for p in midi_positions) else 'MISSED'}")

    # Scenario 3: Interfaces (not endpoints)
    print("\n" + "="*80)
    print("SCENARIO 3: Firmware searching interfaces (not endpoints)")
    print("="*80)
    interfaces = []
    seen_interfaces = set()
    for intf in cfg:
        if intf.bInterfaceNumber not in seen_interfaces:
            seen_interfaces.add(intf.bInterfaceNumber)
            midi = intf.bInterfaceClass == 1 and intf.bInterfaceSubClass == 3
            has_eps = any(i.bNumEndpoints > 0 for i in cfg if i.bInterfaceNumber == intf.bInterfaceNumber)
            interfaces.append({
                'num': intf.bInterfaceNumber,
                'class': intf.bInterfaceClass,
                'subclass': intf.bInterfaceSubClass,
                'midi': midi,
                'has_endpoints': has_eps
            })

    for i, intf in enumerate(interfaces, 1):
        marker = " <- MIDI" if intf['midi'] else ""
        eps = " (has endpoints)" if intf['has_endpoints'] else " (no endpoints)"
        print(f"{i}. Interface {intf['num']} - Class {intf['class']}.{intf['subclass']}{eps}{marker}")

    midi_positions = [i+1 for i, intf in enumerate(interfaces) if intf['midi']]
    if midi_positions:
        print(f"\nMIDI interface at position: {midi_positions}")
        print(f"Searching first 6 interfaces: {'FOUND' if all(p <= 6 for p in midi_positions) else 'MISSED'}")

    # Scenario 4: Only interfaces with endpoints in alt 0
    print("\n" + "="*80)
    print("SCENARIO 4: Only interfaces WITH endpoints in default alt setting")
    print("="*80)
    interfaces_with_eps = []
    for intf in cfg:
        if intf.bAlternateSetting == 0 and intf.bNumEndpoints > 0:
            midi = intf.bInterfaceClass == 1 and intf.bInterfaceSubClass == 3
            interfaces_with_eps.append({
                'num': intf.bInterfaceNumber,
                'class': intf.bInterfaceClass,
                'subclass': intf.bInterfaceSubClass,
                'eps': intf.bNumEndpoints,
                'midi': midi
            })

    for i, intf in enumerate(interfaces_with_eps, 1):
        marker = " <- MIDI" if intf['midi'] else ""
        print(f"{i}. Interface {intf['num']} - Class {intf['class']}.{intf['subclass']} ({intf['eps']} endpoints){marker}")

    midi_positions = [i+1 for i, intf in enumerate(interfaces_with_eps) if intf['midi']]
    if midi_positions:
        print(f"\nMIDI interface at position: {midi_positions}")
        print(f"Searching first 6: {'FOUND' if all(p <= 6 for p in midi_positions) else 'MISSED'}")
    else:
        print("\nNO MIDI FOUND IN THIS SCENARIO")

def get_endpoint_type(attr):
    types = {0x00: "Control", 0x01: "Isochronous", 0x02: "Bulk", 0x03: "Interrupt"}
    return types.get(attr, "Unknown")

if __name__ == "__main__":
    main()
