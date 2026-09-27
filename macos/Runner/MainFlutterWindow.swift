import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    
    // Atur ukuran jendela awal menyerupai layar smartphone (centered)
    let targetWidth: CGFloat = 430
    let targetHeight: CGFloat = 900
    let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let originX = screenRect.midX - (targetWidth / 2)
    let originY = screenRect.midY - (targetHeight / 2)
    let phoneFrame = NSRect(x: originX, y: originY, width: targetWidth, height: targetHeight)
    self.setFrame(phoneFrame, display: true)
    self.minSize = NSSize(width: 360, height: 640)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
