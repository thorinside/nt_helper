# USB Audio Routing Support - Lite Summary

Implement specialized routing support for the USB Audio (From Host) algorithm which uses a non-standard parameter structure with 8 outputs configured through separate parameter pages. This will create a new UsbFromAlgorithmRouting subclass to handle the unique 'to' parameters and extended bus values including ES-5 L/R destinations, enabling proper visualization of USB audio routing in the routing editor.

## Key Points
- Create UsbFromAlgorithmRouting class to handle non-standard USB Audio algorithm structure
- Support 8 outputs configured through separate parameter pages instead of standard routing
- Handle extended bus values including ES-5 L/R destinations beyond standard 1-20 range