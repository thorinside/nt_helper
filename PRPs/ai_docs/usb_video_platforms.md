# USB Video Platform Implementation Guide

## Platform-Specific Requirements

### Android Implementation

#### Permissions Required
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.USB_PERMISSION" />
<uses-feature android:name="android.hardware.usb.host" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.external" android:required="false" />
```

#### USB Device Detection
```kotlin
private fun detectDistingNT(usbManager: UsbManager): UsbDevice? {
    val DISTING_VENDOR_ID = 0x3773  // Expert Sleepers vendor ID (verified)
    val DISTING_PRODUCT_ID = 0x0001  // Disting NT product ID (verified)
    
    return usbManager.deviceList.values.find { device ->
        device.vendorId == DISTING_VENDOR_ID && 
        device.productId == DISTING_PRODUCT_ID
    }
}
```

#### Known Issues
- Android 10+ with targetSdkVersion 28+ may block UVC devices
- Solution: Set targetSdkVersion to 27 or request USB permissions explicitly
- Some devices require root access for /dev/video* access

### iOS Implementation  

#### Requirements
- iOS 17.0+ for external camera support
- Lightning to USB 3 Camera Adapter or USB-C adapter
- Camera permissions in Info.plist

#### Info.plist Configuration
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to display video from your Disting NT</string>
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.expertsleepers.disting</string>
</array>
```

#### Swift Implementation
```swift
import AVFoundation

class UsbVideoCapturePlugin: NSObject, FlutterPlugin {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    private func findDistingNTCamera() -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external], // iOS 17+ only
            mediaType: .video,
            position: .unspecified
        )
        
        return discoverySession.devices.first { device in
            // Check if device name contains "Disting" or matches known identifiers
            device.localizedName.contains("Disting") ||
            device.modelID == "Disting NT"
        }
    }
    
    @available(iOS 17.0, *)
    private func startVideoCapture(device: AVCaptureDevice) throws {
        captureSession = AVCaptureSession()
        let input = try AVCaptureDeviceInput(device: device)
        
        if captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
        }
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput!.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video"))
        
        if captureSession!.canAddOutput(videoOutput!) {
            captureSession!.addOutput(videoOutput!)
        }
        
        captureSession!.startRunning()
    }
}
```

### macOS Implementation

#### Requirements
- macOS 10.14+ for AVFoundation external camera support  
- Camera permissions in Info.plist
- Entitlements for camera access

#### Entitlements File
```xml
<key>com.apple.security.device.camera</key>
<true/>
<key>com.apple.security.device.usb</key>
<true/>
```

#### Swift Implementation
```swift
import AVFoundation
import CoreMediaIO

class UsbVideoCapturePlugin: NSObject, FlutterPlugin {
    private func enableExternalCameras() {
        // Enable detection of external cameras
        var prop = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var allow: UInt32 = 1
        CMIOObjectSetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &prop,
            0,
            nil,
            UInt32(MemoryLayout.size(ofValue: allow)),
            &allow
        )
    }
    
    private func listUSBCameras() -> [AVCaptureDevice] {
        enableExternalCameras()
        
        return AVCaptureDevice.devices(for: .video).filter { device in
            // Filter for external USB cameras
            device.transportType == .usb ||
            device.localizedName.contains("USB") ||
            device.localizedName.contains("Disting")
        }
    }
}
```

### Windows Implementation

#### Media Foundation Setup
```cpp
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>

class UsbVideoCapturePlugin : public flutter::Plugin {
private:
    IMFSourceReader* sourceReader = nullptr;
    
    HRESULT InitializeMediaFoundation() {
        HRESULT hr = MFStartup(MF_VERSION);
        if (FAILED(hr)) {
            return hr;
        }
        
        // Enumerate video devices
        IMFAttributes* attributes = nullptr;
        hr = MFCreateAttributes(&attributes, 1);
        if (SUCCEEDED(hr)) {
            hr = attributes->SetGUID(
                MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
                MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID
            );
        }
        
        return hr;
    }
    
    std::vector<DeviceInfo> EnumerateVideoCameras() {
        std::vector<DeviceInfo> devices;
        IMFActivate** ppDevices = nullptr;
        UINT32 count = 0;
        
        HRESULT hr = MFEnumDeviceSources(attributes, &ppDevices, &count);
        if (SUCCEEDED(hr)) {
            for (UINT32 i = 0; i < count; i++) {
                WCHAR* friendlyName = nullptr;
                UINT32 nameLength = 0;
                
                ppDevices[i]->GetAllocatedString(
                    MF_DEVSOURCE_ATTRIBUTE_FRIENDLY_NAME,
                    &friendlyName,
                    &nameLength
                );
                
                // Check if this is Disting NT
                if (wcsstr(friendlyName, L"Disting") != nullptr) {
                    DeviceInfo info;
                    info.name = friendlyName;
                    info.index = i;
                    info.isDistingNT = true;
                    devices.push_back(info);
                }
                
                CoTaskMemFree(friendlyName);
            }
        }
        
        return devices;
    }
};
```

#### DirectShow Fallback
```cpp
#include <dshow.h>

HRESULT EnumerateDevicesDirectShow() {
    ICreateDevEnum* pDevEnum = nullptr;
    IEnumMoniker* pEnum = nullptr;
    
    HRESULT hr = CoCreateInstance(
        CLSID_SystemDeviceEnum,
        nullptr,
        CLSCTX_INPROC_SERVER,
        IID_ICreateDevEnum,
        reinterpret_cast<void**>(&pDevEnum)
    );
    
    if (SUCCEEDED(hr)) {
        hr = pDevEnum->CreateClassEnumerator(
            CLSID_VideoInputDeviceCategory,
            &pEnum,
            0
        );
    }
    
    return hr;
}
```

### Linux Implementation

#### V4L2 Setup
```c
#include <linux/videodev2.h>
#include <fcntl.h>
#include <sys/ioctl.h>

class UsbVideoCapturePlugin : public flutter::Plugin {
private:
    int fd = -1;
    
    std::vector<DeviceInfo> EnumerateV4L2Devices() {
        std::vector<DeviceInfo> devices;
        
        for (int i = 0; i < 10; i++) {
            char devicePath[32];
            snprintf(devicePath, sizeof(devicePath), "/dev/video%d", i);
            
            int fd = open(devicePath, O_RDWR | O_NONBLOCK);
            if (fd < 0) continue;
            
            struct v4l2_capability cap;
            if (ioctl(fd, VIDIOC_QUERYCAP, &cap) == 0) {
                // Check if it's a USB device
                if (cap.bus_info[0] == 'u' && cap.bus_info[1] == 's' && cap.bus_info[2] == 'b') {
                    DeviceInfo info;
                    info.path = devicePath;
                    info.name = (char*)cap.card;
                    
                    // Check for Disting NT
                    if (strstr((char*)cap.card, "Disting") != nullptr) {
                        info.isDistingNT = true;
                    }
                    
                    devices.push_back(info);
                }
            }
            
            close(fd);
        }
        
        return devices;
    }
    
    bool StartVideoStream(const char* devicePath) {
        fd = open(devicePath, O_RDWR);
        if (fd < 0) return false;
        
        // Set video format (assuming Disting NT uses 256x64)
        struct v4l2_format fmt;
        fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        fmt.fmt.pix.width = 256;
        fmt.fmt.pix.height = 64;
        fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
        
        if (ioctl(fd, VIDIOC_S_FMT, &fmt) < 0) {
            close(fd);
            return false;
        }
        
        return true;
    }
};
```

#### UVC Driver Configuration
```bash
# Check if UVC driver is loaded
lsmod | grep uvcvideo

# Load UVC driver if not present
sudo modprobe uvcvideo

# Check device permissions
ls -l /dev/video*

# Add user to video group for access
sudo usermod -a -G video $USER
```

## Cross-Platform Considerations

### USB Device Identification
All platforms should identify Disting NT using:
- Vendor ID: 0x3773 (Expert Sleepers - verified on actual hardware)
- Product ID: 0x0001 (Disting NT - verified on actual hardware)
- Device Name: "disting NT" (exact string in AVFoundation)

### Video Format
Verified format from Disting NT (tested on macOS):
- Resolution: 256x64 pixels (confirmed)
- Color: Monochrome/grayscale display
- Frame Rate: 30 FPS (verified with ffmpeg)
- Encoding: Uncompressed video stream
- AVFoundation device index: Usually appears as device [0]

### Error Handling
All platforms must handle:
- Device not found
- Permission denied
- Device disconnection during streaming
- Invalid video format
- Buffer overflow/underflow

### Performance Optimization
- Use hardware acceleration where available
- Implement frame dropping for slow systems
- Use separate thread/isolate for video processing
- Limit buffer size to prevent memory issues

## Testing Checklist

### Per Platform Testing
- [ ] Device enumeration lists Disting NT
- [ ] Video stream starts successfully
- [ ] Frame data is received continuously
- [ ] Disconnection is handled gracefully
- [ ] Reconnection works without restart
- [ ] Memory usage remains stable
- [ ] CPU usage is acceptable (<20%)
- [ ] No interference with MIDI communication

### Cross-Platform Testing
- [ ] Same visual output across platforms
- [ ] Similar performance characteristics
- [ ] Consistent error messages
- [ ] Settings synchronization