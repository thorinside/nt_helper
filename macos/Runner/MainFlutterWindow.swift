import Cocoa
import FlutterMacOS
import bitsdojo_window_macos

class MainFlutterWindow: BitsdojoWindow {
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

    super.awakeFromNib()
  }
}
