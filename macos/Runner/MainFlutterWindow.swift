import Cocoa
import FlutterMacOS
import bitsdojo_window_macos

class MainFlutterWindow: BitsdojoWindow, NSWindowDelegate { // Conforming to NSWindowDelegate
    private var windowEventsChannel: FlutterMethodChannel?

    override func bitsdojo_window_configure() -> UInt {
      return BDW_HIDE_ON_STARTUP
    }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.title = ""  // Empty string

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Register custom plugins
    UsbVideoCapturePlugin.register(with: flutterViewController.registrar(forPlugin: "com.example.nt_helper.UsbVideoCapturePlugin"))

    // Initialize the MethodChannel
    let registrar = flutterViewController.registrar(forPlugin: "com.nt_helper.app.WindowStatePlugin")
    self.windowEventsChannel = FlutterMethodChannel(name: "com.nt_helper.app/window_events",
                                                    binaryMessenger: registrar.messenger) // Removed parentheses

    super.awakeFromNib()
    // Set the window delegate to self to ensure windowShouldClose is called.
    self.delegate = self
  }

  @objc func windowShouldClose(_ sender: NSWindow) -> Bool {
      self.windowEventsChannel?.invokeMethod("windowWillClose", arguments: nil) { (result: Any?) -> Void in
          // This callback is executed when Dart side's MethodCallHandler for "windowWillClose" returns.
          // Diagnostic prints removed as per instructions.
          // Optionally, minimal error logging could be retained here if desired in a real application.

          // IMPORTANT: Ensure UI updates (like closing a window) are on the main thread.
          DispatchQueue.main.async {
              // Call NSWindow's close method directly.
              // This bypasses windowShouldClose and other delegate methods again,
              // preventing a loop and ensuring the window actually closes.
              self.close()
          }
      }
      
      // Return false to prevent the window from closing immediately.
      // The window will be closed programmatically in the invokeMethod's callback.
      return false 
  }
}
