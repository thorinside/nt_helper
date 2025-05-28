import Flutter
import UIKit

public class IosFileAccessPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
    private var channel: FlutterMethodChannel
    private var flutterResultForPicker: FlutterResult?

    // Store URL and its reference count
    private var activeSessions: [String: (url: URL, refCount: Int)] = [:]

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.nt_helper/ios_file_access", binaryMessenger: registrar.messenger())
        let instance = IosFileAccessPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance) 
    }

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "pickDirectoryAndStoreBookmark":
                self.flutterResultForPicker = result
                pickDirectory()
            
            case "startAccessSession":
                guard let args = call.arguments as? [String: Any],
                      let bookmarkedPathKey = args["bookmarkedPathKey"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "bookmarkedPathKey is required for startAccessSession", details: nil))
                    return
                }
                startAccessSession(bookmarkedPathKey: bookmarkedPathKey, result: result)

            case "listDirectoryInSession":
                guard let args = call.arguments as? [String: Any],
                      let sessionId = args["sessionId"] as? String,
                      let directoryPathToList = args["directoryPathToList"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "sessionId and directoryPathToList are required", details: nil))
                    return
                }
                listDirectoryInSession(sessionId: sessionId, directoryPathToList: directoryPathToList, result: result)
            
            case "readFileInSession":
                guard let args = call.arguments as? [String: Any],
                      let sessionId = args["sessionId"] as? String,
                      let filePathToRead = args["filePathToRead"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS_SESSION_READ", message: "sessionId and filePathToRead are required", details: nil))
                    return
                }
                readFileInSession(sessionId: sessionId, filePathToRead: filePathToRead, result: result)

            case "stopAccessSession":
                guard let args = call.arguments as? [String: Any],
                      let sessionId = args["sessionId"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "sessionId is required for stopAccessSession", details: nil))
                    return
                }
                stopAccessSession(sessionId: sessionId, result: result)
            
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    private func pickDirectory() {
        let documentPicker =
            UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(documentPicker, animated: true, completion: nil)
        } else {
            flutterResultForPicker?(FlutterError(code: "INTERNAL_ERROR", message: "Could not present document picker", details: nil))
        }
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            flutterResultForPicker?(FlutterError(code: "PICKER_ERROR", message: "No directory selected or an error occurred.", details: nil))
            return
        }
        
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                do {
                    let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(bookmarkData, forKey: url.path)
                    flutterResultForPicker?(url.path) 
                } catch {
                    flutterResultForPicker?(FlutterError(code: "BOOKMARK_ERROR", message: "Failed to create bookmark: \\(error.localizedDescription)", details: nil))
                }
            } else {
                flutterResultForPicker?(FlutterError(code: "PICKER_ERROR", message: "Selected item is not a directory.", details: nil))
            }
        } else {
            flutterResultForPicker?(FlutterError(code: "PICKER_ERROR", message: "Selected file path does not exist.", details: nil))
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        flutterResultForPicker?(nil) 
    }

    // MARK: - Session Based Methods with Reference Counting

    private func startAccessSession(bookmarkedPathKey: String, result: @escaping FlutterResult) {
        if var existingSession = activeSessions[bookmarkedPathKey] {
            existingSession.refCount += 1
            activeSessions[bookmarkedPathKey] = existingSession
            result(true)
            return
        }

        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkedPathKey) else {
            result(FlutterError(code: "NO_BOOKMARK_SESSION", message: "No bookmark found for path key: \\(bookmarkedPathKey)", details: nil))
            return
        }

        do {
            var isStale = false
            let resolvedUrl = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                let newBookmarkData = try resolvedUrl.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(newBookmarkData, forKey: bookmarkedPathKey)
            }

            var accessGranted = resolvedUrl.startAccessingSecurityScopedResource()
            var attempts = 0
            let maxAttempts = 3
            let delays = [0.1, 0.25, 0.5] 

            while !accessGranted && attempts < maxAttempts {
                attempts += 1
                Thread.sleep(forTimeInterval: delays[attempts-1])
                accessGranted = resolvedUrl.startAccessingSecurityScopedResource()
            }

            if accessGranted {
                activeSessions[bookmarkedPathKey] = (url: resolvedUrl, refCount: 1)
                result(true)
            } else {
                result(FlutterError(code: "SESSION_ACCESS_DENIED", message: "Failed to start security-scoped resource for session \\(bookmarkedPathKey) after \\(maxAttempts) attempts", details: nil))
            }
        } catch {
            result(FlutterError(code: "SESSION_BOOKMARK_ERROR", message: "Error resolving bookmark for session \\(bookmarkedPathKey): \\(error.localizedDescription)", details: nil))
        }
    }

    private func stopAccessSession(sessionId: String, result: @escaping FlutterResult) {
        guard var sessionToStop = activeSessions[sessionId] else {
            result(nil) 
            return
        }
        
        sessionToStop.refCount -= 1

        if sessionToStop.refCount <= 0 {
            sessionToStop.url.stopAccessingSecurityScopedResource()
            activeSessions.removeValue(forKey: sessionId)
        } else {
            activeSessions[sessionId] = sessionToStop 
        }
        result(nil)
    }

    private func listDirectoryInSession(sessionId: String, directoryPathToList: String, result: @escaping FlutterResult) {
        guard let activeSession = activeSessions[sessionId], activeSession.refCount > 0 else {
            result(FlutterError(code: "NO_SESSION", message: "No active session (or refCount <= 0) for ID \\(sessionId)", details: nil))
            return
        }
        
        let scopedRootDirURL = activeSession.url

        let fileManager = FileManager.default
        let targetListURL = URL(fileURLWithPath: directoryPathToList)

        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: targetListURL.path, isDirectory: &isDir), isDir.boolValue else {
            result([]) 
            return
        }

        var entryNames: [String] = []
        do {
            let itemURLs = try fileManager.contentsOfDirectory(at: targetListURL, 
                                                              includingPropertiesForKeys: [.nameKey, .isDirectoryKey, .isPackageKey], 
                                                              options: [.skipsHiddenFiles, .skipsPackageDescendants])
            for itemURL in itemURLs {
                let resourceValues = try itemURL.resourceValues(forKeys: [.nameKey, .isDirectoryKey, .isPackageKey])
                let name = resourceValues.name ?? itemURL.lastPathComponent
                if resourceValues.isPackage == true || resourceValues.isDirectory == true {
                    entryNames.append(name + "/")
                } else {
                    entryNames.append(name)
                }
            }
            result(entryNames)
        } catch {
            result(FlutterError(code: "SESSION_LIST_ERROR", message: "Failed to list contents of directory \\(targetListURL.path) in session: \\(error.localizedDescription)", details: nil))
        }
    }

    private func readFileInSession(sessionId: String, filePathToRead: String, result: @escaping FlutterResult) {
        guard let activeSession = activeSessions[sessionId], activeSession.refCount > 0 else {
            result(FlutterError(code: "NO_SESSION_READ", message: "No active session (or refCount <= 0) for ID \\(sessionId)", details: nil))
            return
        }
        
        let scopedRootDirURL = activeSession.url

        let targetFileUrl = URL(fileURLWithPath: filePathToRead)

        do {
            var isTargetFileDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: targetFileUrl.path, isDirectory: &isTargetFileDirectory) {
                if isTargetFileDirectory.boolValue {
                    result(FlutterError(code: "IS_DIRECTORY_SESSION", message: "Target path is a directory: \\(targetFileUrl.path)", details: nil))
                    return
                }
            } else {
                result(FlutterError(code: "FILE_NOT_FOUND_SESSION", message: "File not found by native FileManager: \\(targetFileUrl.path)", details: nil))
                return
            }
            let fileData = try Data(contentsOf: targetFileUrl)
            result(FlutterStandardTypedData(bytes: fileData))
        } catch {
            result(FlutterError(code: "SESSION_FILE_READ_ERROR", message: "Failed to read file \\(targetFileUrl.path) in session: \\(error.localizedDescription)", details: nil))
        }
    }
} 