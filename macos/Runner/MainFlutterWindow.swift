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

    // Initialize the MethodChannel
    let registrar = flutterViewController.registrar(forPlugin: "com.nt_helper.app.WindowStatePlugin")
    self.windowEventsChannel = FlutterMethodChannel(name: "com.nt_helper.app/window_events",
                                                    binaryMessenger: registrar.messenger) // Removed parentheses

    super.awakeFromNib()
    // Set the window delegate to self to ensure windowShouldClose is called.
    self.delegate = self
  }

  @objc func windowShouldClose(_ sender: NSWindow) -> Bool { // Added @objc, removed override
    print("Swift: windowShouldClose called. Sending 'windowWillClose' event to Dart.")
    self.windowEventsChannel?.invokeMethod("windowWillClose", arguments: nil)
    // Return true to allow the window to close.
    // We are not waiting for a response from Dart to keep things simple.
    return true
  }
}
