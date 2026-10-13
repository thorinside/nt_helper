import Foundation
import FlutterMacOS

final class Messenger: NSObject, FlutterBinaryMessenger {
  var received: FlutterMethodCall?
  var response: Any? = ["hostId": "host-1", "connectionId": 7, "sessionId": "7:1", "potValues": [2080, 2016, 2072]]
  let codec = FlutterStandardMethodCodec.sharedInstance()
  func send(onChannel channel: String, message: Data?) {
    send(onChannel: channel, message: message, binaryReply: nil)
  }
  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {
    precondition(channel == "mixin.one/desktop_multi_window/channels")
    received = codec.decodeMethodCall(message!)
    if let error = response as? FlutterError {
      callback?(codec.encodeErrorEnvelope(error))
    } else {
      callback?(codec.encodeSuccessEnvelope(response))
    }
  }
  func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?) -> FlutterBinaryMessengerConnection { 1 }
  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}
}

@main
struct BackendTest {
  static func main() {
    let messenger = Messenger()
    let channel = FlutterMethodChannel(name: "mixin.one/desktop_multi_window/channels", binaryMessenger: messenger)
    var authority: WindowChannel? = WindowChannel(methodChannel: channel)
    let popup = WindowChannel(methodChannel: channel)
    let name = "nt_helper/video_popup"
    authority!.handle(FlutterMethodCall(methodName: "registerMethodHandler", arguments: ["channel": name, "mode": "unidirectional"])) { result in
      precondition(result == nil)
    }
    for method in ["remoteAcquire", "remoteRead", "remoteOpen", "remoteAction", "remoteClose", "remoteDetach"] {
      let args: [String: Any] = ["channel": name, "method": method, "arguments": ["hostId": "host-1", "connectionId": 7, "sessionId": "7:1"]]
      var completed = false
      popup.handle(FlutterMethodCall(methodName: "invokeMethod", arguments: args)) { result in
        let snapshot = result as! [String: Any]
        precondition(snapshot["hostId"] as! String == "host-1")
        completed = true
      }
      precondition(completed)
      precondition(messenger.received!.method == "methodCall")
      let forwarded = messenger.received!.arguments as! [String: Any]
      precondition(forwarded["method"] as! String == method)
      let payload = forwarded["arguments"] as! [String: Any]
      precondition(payload["connectionId"] as! Int == 7)
    }
    messenger.response = FlutterError(code: "remote_failed", message: "device state is unknown", details: nil)
    popup.handle(FlutterMethodCall(methodName: "invokeMethod", arguments: ["channel": name, "method": "remoteAction", "arguments": "invalid"])) { result in
      precondition((result as! FlutterError).code == "remote_failed")
    }
    let invalid = messenger.received!.arguments as! [String: Any]
    precondition(invalid["arguments"] as! String == "invalid")
    // The real installed registry removes dead main engines; commands cannot
    // silently succeed or route to a newly registered authority.
    authority = nil
    popup.handle(FlutterMethodCall(methodName: "invokeMethod", arguments: ["channel": name, "method": "remoteAction", "arguments": "invalid"])) { result in
      precondition((result as! FlutterError).code == "CHANNEL_UNREGISTERED")
    }
    print("desktop_multi_window macOS installed native WindowChannel: registration, six remote methods, identities/state/results and dead-main rejection passed. Fake Flutter messenger; no OS windows/device execution.")
  }
}
