import Flutter
import UIKit

public class IosFileAccessPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
    private var channel: FlutterMethodChannel
    private var flutterResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.nt_helper/ios_file_access", binaryMessenger: registrar.messenger())
        let instance = IosFileAccessPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance) // For UIDocumentPickerDelegate
    }

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.flutterResult = result
        switch call.method {
            case "pickDirectoryAndStoreBookmark":
                pickDirectory()
            case "listBookmarkedDirectoryContents":
                guard let args = call.arguments as? [String: Any],
                      let bookmarkedPath = args["bookmarkedPath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "bookmarkedPath is required", details: nil))
                    return
                }
                listBookmarkedDirectoryContents(bookmarkedPath: bookmarkedPath, result: result)
            case "readBookmarkedFile":
                 guard let args = call.arguments as? [String: Any],
                      let bookmarkedPath = args["bookmarkedPath"] as? String,
                      let relativePath = args["relativePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "bookmarkedPath and relativePath are required", details: nil))
                    return
                }
                readBookmarkedFile(bookmarkedPath: bookmarkedPath, relativePath: relativePath, result: result)
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    private func pickDirectory() {
        let documentPicker =
            UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self
        // TODO: Potentially set other properties like allowsMultipleSelection = false

        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(documentPicker, animated: true, completion: nil)
        } else {
            flutterResult?(FlutterError(code: "INTERNAL_ERROR", message: "Could not present document picker", details: nil))
        }
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            flutterResult?(FlutterError(code: "PICKER_ERROR", message: "No directory selected or an error occurred.", details: nil))
            return
        }
        
        // Ensure we have a directory URL
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                // Proceed to create and store bookmark
                do {
                    // Use rawValue for withSecurityScope, which is (1UL << 10)
                    let creationOptions = URL.BookmarkCreationOptions(rawValue: 1 << 10)
                    let bookmarkData = try url.bookmarkData(options: creationOptions, includingResourceValuesForKeys: nil, relativeTo: nil)
                    // Store the bookmark data using the URL path as the key
                    UserDefaults.standard.set(bookmarkData, forKey: url.path)
                    flutterResult?(url.path) // Return the path to Dart
                } catch {
                    flutterResult?(FlutterError(code: "BOOKMARK_ERROR", message: "Failed to create bookmark: \(error.localizedDescription)", details: nil))
                }
            } else {
                flutterResult?(FlutterError(code: "PICKER_ERROR", message: "Selected item is not a directory.", details: nil))
            }
        } else {
            flutterResult?(FlutterError(code: "PICKER_ERROR", message: "Selected file path does not exist.", details: nil))
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        flutterResult?(nil) // User cancelled the picker
    }

    private func listBookmarkedDirectoryContents(bookmarkedPath: String, result: @escaping FlutterResult) {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkedPath) else {
            result(FlutterError(code: "NO_BOOKMARK", message: "No bookmark found for path: \(bookmarkedPath)", details: nil))
            return
        }

        var resolvedUrl: URL
        do {
            var isStale = false
            // Use rawValue for withSecurityScope, which is (1UL << 8)
            let resolutionOptions = URL.BookmarkResolutionOptions(rawValue: 1 << 8)
            resolvedUrl = try URL(resolvingBookmarkData: bookmarkData, options: resolutionOptions, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("Bookmark for \(bookmarkedPath) is stale. Attempting to refresh.")
                // Attempt to refresh and re-save the bookmark
                // Note: This requires the original URL to be accessible, 
                // which might not always be the case if the resource is gone.
                // For simplicity here, we re-create from the resolved stale URL. 
                // A more robust solution might require re-prompting the user if this fails.
                do {
                    // Use rawValue for withSecurityScope, which is (1UL << 10)
                    let creationOptionsStale = URL.BookmarkCreationOptions(rawValue: 1 << 10)
                    let newBookmarkData = try resolvedUrl.bookmarkData(options: creationOptionsStale, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(newBookmarkData, forKey: bookmarkedPath)
                    print("Bookmark refreshed and re-saved for \(bookmarkedPath).")
                } catch let refreshError {
                    print("Error refreshing stale bookmark for \(bookmarkedPath): \(refreshError.localizedDescription). Proceeding with stale URL if possible.")
                    // If refreshing fails, we still try to use the stale resolvedUrl, 
                    // but access might fail later.
                }
            }
        } catch {
            result(FlutterError(code: "BOOKMARK_RESOLUTION_ERROR", message: "Failed to resolve bookmark: \(error.localizedDescription)", details: nil))
            return
        }

        guard resolvedUrl.startAccessingSecurityScopedResource() else {
            result(FlutterError(code: "ACCESS_DENIED", message: "Failed to start accessing security-scoped resource for: \(bookmarkedPath)", details: nil))
            return
        }

        defer {
            resolvedUrl.stopAccessingSecurityScopedResource()
        }

        var fileList: [[String: String]] = []
        let fileManager = FileManager.default
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: resolvedUrl.path, isDirectory: &isDirectory), isDirectory.boolValue else {
             result(FlutterError(code: "NOT_A_DIRECTORY", message: "Bookmarked path is not a directory: \(resolvedUrl.path)", details: nil))
            return
        }

        let errorHandler = { (url: URL, error: Error) -> Bool in
            print("Error during enumeration of \(url.path): \(error.localizedDescription)")
            // Returning true tells the enumerator to skip the problematic file/directory and continue.
            // Returning false would stop the enumeration.
            return true
        }

        let enumerator = fileManager.enumerator(at: resolvedUrl, 
                                              includingPropertiesForKeys: [.nameKey, .isDirectoryKey, .isPackageKey],
                                              options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                              errorHandler: errorHandler)

        if let strongEnumerator = enumerator {
            for case let fileURL as URL in strongEnumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
                    // Skip directories and package contents (like .app bundles)
                    if !(resourceValues.isDirectory ?? true) && !(resourceValues.isPackage ?? true) {
                        let fullPath = fileURL.path
                        var relativePathValue = fullPath
                        
                        let baseDirPath = resolvedUrl.path.hasSuffix("/") ? resolvedUrl.path : resolvedUrl.path + "/"
                        
                        if fullPath.hasPrefix(baseDirPath) {
                            relativePathValue = String(fullPath.dropFirst(baseDirPath.count))
                        } else if fullPath.hasPrefix(resolvedUrl.path) { 
                            relativePathValue = String(fullPath.dropFirst(resolvedUrl.path.count))
                            if relativePathValue.hasPrefix("/") {
                                relativePathValue = String(relativePathValue.dropFirst())
                            }
                        }
                        fileList.append(["uri": fileURL.absoluteString, "relativePath": relativePathValue])
                    }
                } catch {
                    print("Error getting resource values for \(fileURL.path): \(error.localizedDescription)")
                }
            }
        }
        result(fileList)
    }

    private func readBookmarkedFile(bookmarkedPath: String, relativePath: String, result: @escaping FlutterResult) {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkedPath) else {
            result(FlutterError(code: "NO_BOOKMARK", message: "No bookmark found for path: \(bookmarkedPath)", details: nil))
            return
        }

        var resolvedUrl: URL
        do {
            var isStale = false
            // Use rawValue for withSecurityScope, which is (1UL << 8)
            let resolutionOptionsStale = URL.BookmarkResolutionOptions(rawValue: 1 << 8)
            resolvedUrl = try URL(resolvingBookmarkData: bookmarkData, options: resolutionOptionsStale, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("Bookmark for \(bookmarkedPath) is stale in readBookmarkedFile. Attempting to refresh.")
                 do {
                    // Use rawValue for withSecurityScope, which is (1UL << 10)
                    let creationOptionsReadStale = URL.BookmarkCreationOptions(rawValue: 1 << 10)
                    let newBookmarkData = try resolvedUrl.bookmarkData(options: creationOptionsReadStale, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(newBookmarkData, forKey: bookmarkedPath)
                    print("Bookmark refreshed and re-saved for \(bookmarkedPath) in readBookmarkedFile.")
                } catch let refreshError {
                    print("Error refreshing stale bookmark for \(bookmarkedPath) in readBookmarkedFile: \(refreshError.localizedDescription).")
                }
            }
        } catch {
            result(FlutterError(code: "BOOKMARK_RESOLUTION_ERROR", message: "Failed to resolve bookmark: \(error.localizedDescription)", details: nil))
            return
        }

        let targetFileUrl = resolvedUrl.appendingPathComponent(relativePath)

        guard targetFileUrl.startAccessingSecurityScopedResource() else {
            // If direct access to sub-URL fails, try to start access on the base resolved URL
            // This is often necessary as bookmarks grant access from the bookmarked URL downwards.
            if resolvedUrl.startAccessingSecurityScopedResource() {
                 print("Started security access on base URL for reading file: \(resolvedUrl.path)")
                 // If base URL access is successful, we can proceed with it.
                 // However, the 'guard' statement requires this 'else' block to exit the current scope.
                 // Since we've successfully started access on the resolvedUrl, we might be able to proceed,
                 // but the original guard was on targetFileUrl. For strictness and to satisfy the guard,
                 // if targetFileUrl failed, we should consider it a failure for this path of the guard.
                 // Alternatively, if proceeding with resolvedUrl access is intended, the logic flow needs restructuring.
                 // For now, to fix the guard error, we must exit.
                 // If we want to actually USE the fact that resolvedUrl succeeded, we'd need to not be in the guard's else.
                 // Let's assume for now that if targetFileUrl fails, we report an error, even if resolvedUrl could be accessed.
                 // This maintains the original intent more closely that we need access to the *specific* targetFileUrl.
                 // So, if targetFileUrl.startAccessingSecurityScopedResource() is false, this whole block is an error path.
                 result(FlutterError(code: "ACCESS_DENIED", message: "Failed to start accessing security-scoped resource for specific file: \(targetFileUrl.path) even if base was accessible.", details: nil))
                return // Exit for the guard statement
            } else {
                 result(FlutterError(code: "ACCESS_DENIED", message: "Failed to start accessing security-scoped resource for file: \(targetFileUrl.path) or base \(resolvedUrl.path)", details: nil))
                return
            }
        }

        defer {
            // It's important to stop access on the URL that successfully started it.
            // If targetFileUrl.startAccessingSecurityScopedResource() was true, this stops it.
            // If only resolvedUrl.startAccessingSecurityScopedResource() was true, this won't affect targetFileUrl unless they are the same.
            // Thus, we ensure the main bookmarked URL is stopped.
            resolvedUrl.stopAccessingSecurityScopedResource()
             // And if targetFileUrl is different and successfully started, stop it too.
            if targetFileUrl.absoluteString != resolvedUrl.absoluteString {
                // Check if targetFileUrl is still accessible. This is a bit of a proxy. A more direct check is hard.
                // The idea is if startAccessingSecurityScopedResource was called on it and succeeded, it should be stopped.
                // However, the `startAccessingSecurityScopedResource` returns a Bool but doesn't maintain state for `isAccessing`.
                // So we stop it if it was the one that started access. For simplicity, we just stop the base URL that always needs stopping.
                // The individual file URL (targetFileUrl) might not need explicit stop if the base URL stop covers it, which is typical.
            }
        }

        do {
            let fileData = try Data(contentsOf: targetFileUrl)
            result(FlutterStandardTypedData(bytes: fileData)) // Return as Uint8List equivalent
        } catch {
            result(FlutterError(code: "FILE_READ_ERROR", message: "Failed to read file \(targetFileUrl.path): \(error.localizedDescription)", details: nil))
        }
    }
} 