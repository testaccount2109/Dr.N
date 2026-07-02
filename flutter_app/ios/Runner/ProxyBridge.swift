import Flutter
import UIKit
import drnbind

public class SwiftProxyBridge {
    private let core = Core()

    func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "drn.app/proxy",
            binaryMessenger: registrar.messenger()
        )

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }

            do {
                switch call.method {
                case "getServers":
                    result(self.core.getServersJSON())

                case "getStatus":
                    result(self.core.getStatusJSON())

                case "addServer":
                    let args = call.arguments as? [String: String] ?? [:]
                    self.core.addServer(
                        args["name"] ?? "",
                        address: args["address"] ?? "",
                        port: args["port"] ?? "19132"
                    )
                    result(nil)

                case "removeServer":
                    let args = call.arguments as? [String: String] ?? [:]
                    self.core.removeServer(args["id"] ?? "")
                    result(nil)

                case "startProxy":
                    let args = call.arguments as? [String: String] ?? [:]
                    try self.core.startProxy(
                        args["address"] ?? "",
                        serverPort: args["port"] ?? "19132"
                    )
                    result(nil)

                case "stopProxy":
                    try self.core.stopProxy()
                    result(nil)

                default:
                    result(FlutterMethodNotImplemented)
                }
            } catch {
                result(FlutterError(
                    code: "PROXY_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }
}

// Plugin registration for iOS
public class DrNPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let bridge = SwiftProxyBridge()
        bridge.register(with: registrar)
    }
}