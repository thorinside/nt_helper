# Spec Requirements Document

> Spec: USB Audio Routing Support
> Created: 2025-09-08
> Status: Planning

## Overview

Implement specialized routing support for the USB Audio (From Host) algorithm which uses a non-standard parameter structure with 8 outputs configured through separate parameter pages. This will enable proper visualization and connection discovery for USB audio routing in the routing editor.

## User Stories

### USB Audio Configuration

As a Disting NT user, I want to see and configure USB Audio (From Host) algorithm routing in the visual editor, so that I can properly route USB audio channels to hardware outputs or other algorithms.

When using the USB Audio (From Host) algorithm, I need to:
1. See all 8 USB audio channels as output ports in the routing visualization
2. Configure each channel's destination using the familiar routing interface
3. Understand the output mode (Add/Replace) for each channel
4. Route to standard outputs, aux buses, or ES-5 L/R destinations

## Spec Scope

1. **UsbFromAlgorithmRouting Class** - New AlgorithmRouting subclass specifically for the 'usbf' algorithm GUID
2. **Port Extraction Logic** - Extract 8 output ports from parameter pages, using page names for port identification
3. **Bus Value Mapping** - Handle extended enum values including ES-5 L/R destinations with max value of 30
4. **Factory Integration** - Update AlgorithmRouting.fromSlot() factory to instantiate UsbFromAlgorithmRouting for 'usbf' GUID
5. **Connection Discovery** - Ensure ConnectionDiscoveryService properly handles USB audio outputs with extended bus range
6. **Remove Fallback Ports** - Eliminate automatic generation of default "Main 1 Audio Out", "Main 1 CV Out", "Main 1 Audio In", "Main 1 CV In" ports
7. **Exclude Empty Nodes** - Algorithms with no ports (like 'note' algorithm) should be excluded from routing visualization entirely

## Out of Scope

- Modifying the existing PolyAlgorithmRouting or MultiChannelAlgorithmRouting classes
- Changing the core bus assignment logic for standard algorithms
- Adding USB audio input support (this is From Host only)
- Modifying the visualization layer components

## Expected Deliverable

1. USB Audio (From Host) algorithm displays 8 output ports named after parameter pages in the routing editor
2. Connections from USB audio outputs to destinations are automatically discovered and visualized
3. ES-5 L/R destinations appear correctly in the routing visualization
4. No fallback "Main 1" ports appear for any algorithm
5. Algorithms with no ports (e.g., 'note' algorithm) are excluded from routing visualization

## Spec Documentation

- Tasks: @.agent-os/specs/2025-09-08-usb-audio-routing-support/tasks.md
- Technical Specification: @.agent-os/specs/2025-09-08-usb-audio-routing-support/sub-specs/technical-spec.md