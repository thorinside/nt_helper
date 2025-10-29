#!/usr/bin/env python3
"""
Query USB device endpoints for disting NT
Requires: pip install pyusb
"""

import usb.core
import usb.util

# disting NT identifiers
VENDOR_ID = 0x3773
PRODUCT_ID = 0x0001

def main():
    # Find the device
    dev = usb.core.find(idVendor=VENDOR_ID, idProduct=PRODUCT_ID)

    if dev is None:
        print(f"Device not found (VID: 0x{VENDOR_ID:04x}, PID: 0x{PRODUCT_ID:04x})")
        return

    print(f"Found: {dev.manufacturer} {dev.product}")
    print(f"Serial: {dev.serial_number}")
    print(f"Bus: {dev.bus}, Address: {dev.address}")
    print(f"USB Version: {dev.bcdUSB:#06x}")
    print(f"Device Version: {dev.bcdDevice:#06x}")
    print(f"Device Class: {dev.bDeviceClass}")
    print(f"Max Packet Size: {dev.bMaxPacketSize0}")
    print(f"Configurations: {dev.bNumConfigurations}")
    print()

    # Track all endpoints in order
    all_endpoints = []

    # Iterate through configurations
    for cfg in dev:
        print(f"Configuration {cfg.bConfigurationValue}:")
        print(f"  Interfaces: {cfg.bNumInterfaces}")
        print(f"  Max Power: {cfg.bMaxPower * 2}mA")
        print()

        # Iterate through interfaces
        for intf in cfg:
            print(f"  Interface {intf.bInterfaceNumber}:")
            print(f"    Alternate Setting: {intf.bAlternateSetting}")
            print(f"    Class: {intf.bInterfaceClass} ({get_class_name(intf.bInterfaceClass)})")
            print(f"    SubClass: {intf.bInterfaceSubClass}")
            print(f"    Protocol: {intf.bInterfaceProtocol}")
            print(f"    Endpoints: {intf.bNumEndpoints}")

            if intf.bNumEndpoints > 0:
                print()
                # Iterate through endpoints
                for ep in intf:
                    ep_addr = ep.bEndpointAddress
                    ep_num = ep_addr & 0x0F
                    direction = "IN " if ep_addr & 0x80 else "OUT"
                    ep_type = get_endpoint_type(ep.bmAttributes & 0x03)

                    print(f"      Endpoint {ep_num} ({direction}):")
                    print(f"        Address: 0x{ep_addr:02x}")
                    print(f"        Type: {ep_type}")
                    print(f"        Max Packet Size: {ep.wMaxPacketSize}")
                    print(f"        Interval: {ep.bInterval}")
                    print()

                    all_endpoints.append({
                        'interface': intf.bInterfaceNumber,
                        'alt_setting': intf.bAlternateSetting,
                        'ep_num': ep_num,
                        'address': ep_addr,
                        'direction': direction.strip(),
                        'type': ep_type,
                        'class': intf.bInterfaceClass,
                        'subclass': intf.bInterfaceSubClass
                    })
            else:
                print()

    # Print enumeration order summary
    print("\n" + "="*80)
    print("ENDPOINT ENUMERATION ORDER (as firmware would see them):")
    print("="*80)
    for i, ep in enumerate(all_endpoints, 1):
        midi_marker = " <- MIDI" if ep['class'] == 1 and ep['subclass'] == 3 else ""
        print(f"{i}. EP{ep['ep_num']} (0x{ep['address']:02x}) - {ep['direction']:3s} - {ep['type']:12s} - "
              f"Interface {ep['interface']}.{ep['alt_setting']}{midi_marker}")

    print(f"\nTotal endpoints found: {len(all_endpoints)}")

    # Find MIDI endpoints
    midi_eps = [ep for ep in all_endpoints if ep['class'] == 1 and ep['subclass'] == 3]
    if midi_eps:
        print(f"\nMIDI endpoints appear at positions: {[all_endpoints.index(ep) + 1 for ep in midi_eps]}")
        print(f"If firmware only searches first 6 endpoints, it would {'FIND' if all_endpoints.index(midi_eps[0]) < 6 else 'MISS'} MIDI")

def get_class_name(class_code):
    classes = {
        0x00: "Device",
        0x01: "Audio",
        0x02: "Communications",
        0x03: "HID",
        0x05: "Physical",
        0x06: "Image",
        0x07: "Printer",
        0x08: "Mass Storage",
        0x09: "Hub",
        0x0A: "CDC-Data",
        0x0B: "Smart Card",
        0x0D: "Content Security",
        0x0E: "Video",
        0x0F: "Personal Healthcare",
        0x10: "Audio/Video",
        0xDC: "Diagnostic",
        0xE0: "Wireless",
        0xEF: "Miscellaneous",
        0xFE: "Application Specific",
        0xFF: "Vendor Specific"
    }
    return classes.get(class_code, "Unknown")

def get_endpoint_type(attr):
    types = {
        0x00: "Control",
        0x01: "Isochronous",
        0x02: "Bulk",
        0x03: "Interrupt"
    }
    return types.get(attr, "Unknown")

if __name__ == "__main__":
    main()
