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
            print("IosFileAccessPlugin: Resolved bookmarked URL: \(resolvedUrl.absoluteString)")
            print("IosFileAccessPlugin: Resolved bookmarked path: \(resolvedUrl.path)")
            
            if isStale {
                print("IosFileAccessPlugin: Bookmark for \(bookmarkedPath) is stale. Attempting to refresh.")
                do {
                    let creationOptionsStale = URL.BookmarkCreationOptions(rawValue: 1 << 10)
                    let newBookmarkData = try resolvedUrl.bookmarkData(options: creationOptionsStale, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(newBookmarkData, forKey: bookmarkedPath)
                    print("Bookmark refreshed and re-saved for \(bookmarkedPath).")
                } catch let refreshError {
                    print("Error refreshing stale bookmark for \(bookmarkedPath): \(refreshError.localizedDescription). Proceeding with stale URL if possible.")
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

        var fullPathList: [String] = []
        let fileManager = FileManager.default
        let presetsFolderName = "presets"
        
        let presetsDirectoryUrl = resolvedUrl.appendingPathComponent(presetsFolderName)
        print("IosFileAccessPlugin: Checking for presets directory at: \(presetsDirectoryUrl.path)")

        var isPresetsDir: ObjCBool = false
        guard fileManager.fileExists(atPath: presetsDirectoryUrl.path, isDirectory: &isPresetsDir), isPresetsDir.boolValue else {
            print("IosFileAccessPlugin: Presets directory not found or is not a directory at \(presetsDirectoryUrl.path). Returning empty list.")
            result(fullPathList) // Return empty list of strings
            return
        }
        
        print("IosFileAccessPlugin: Presets directory found. Enumerating within: \(presetsDirectoryUrl.path)")

        let errorHandler = { (url: URL, error: Error) -> Bool in
            print("Error during enumeration of \(url.path): \(error.localizedDescription)")
            return true
        }

        let enumerator = fileManager.enumerator(at: presetsDirectoryUrl, // Enumerate starting from the presets directory
                                              includingPropertiesForKeys: [.nameKey, .isDirectoryKey, .isPackageKey],
                                              options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                              errorHandler: errorHandler)

        if let strongEnumerator = enumerator {
            for case let fileURL as URL in strongEnumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
                    if !(resourceValues.isDirectory ?? true) && !(resourceValues.isPackage ?? true) {
                        // We are only interested in files. Check if it's a .json file.
                        if fileURL.pathExtension.lowercased() == "json" {
                            print("IosFileAccessPlugin: Enumerator found JSON file: \(fileURL.absoluteString)")
                            fullPathList.append(fileURL.absoluteString) // Add full URI string
                        } else {
                            print("IosFileAccessPlugin: Enumerator skipped non-JSON file: \(fileURL.path)")
                        }
                    } else {
                        print("IosFileAccessPlugin: Enumerator skipped directory or package: \(fileURL.path)")
                    }
                } catch {
                    print("IosFileAccessPlugin: Error getting resource values for \(fileURL.path): \(error.localizedDescription)")
                }
            }
        }
        print("IosFileAccessPlugin: Final fullPathList to be sent to Dart: \(fullPathList)")
        result(fullPathList) // Return list of full URI strings
    }

    private func readBookmarkedFile(bookmarkedPath: String, relativePath: String, result: @escaping FlutterResult) {
        print("IosFileAccessPlugin: readBookmarkedFile called. BookmarkedPath: \(bookmarkedPath), RelativePath: \(relativePath)")
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkedPath) else {
            print("IosFileAccessPlugin: readBookmarkedFile - No bookmark data found for path: \(bookmarkedPath)")
            result(FlutterError(code: "NO_BOOKMARK", message: "No bookmark found for path: \(bookmarkedPath)", details: nil))
            return
        }
        print("IosFileAccessPlugin: readBookmarkedFile - Found bookmark data.")

        var resolvedUrl: URL
        do {
            var isStale = false
            let resolutionOptionsStale = URL.BookmarkResolutionOptions(rawValue: 1 << 8)
            resolvedUrl = try URL(resolvingBookmarkData: bookmarkData, options: resolutionOptionsStale, relativeTo: nil, bookmarkDataIsStale: &isStale)
            print("IosFileAccessPlugin: readBookmarkedFile - Resolved bookmarked URL: \(resolvedUrl.path)")
            
            if isStale {
                print("IosFileAccessPlugin: readBookmarkedFile - Bookmark for \(bookmarkedPath) is stale. Attempting to refresh.")
                 do {
                    let creationOptionsReadStale = URL.BookmarkCreationOptions(rawValue: 1 << 10)
                    let newBookmarkData = try resolvedUrl.bookmarkData(options: creationOptionsReadStale, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(newBookmarkData, forKey: bookmarkedPath)
                    print("IosFileAccessPlugin: readBookmarkedFile - Bookmark refreshed and re-saved for \(bookmarkedPath).")
                } catch let refreshError {
                    print("IosFileAccessPlugin: readBookmarkedFile - Error refreshing stale bookmark for \(bookmarkedPath): \(refreshError.localizedDescription).")
                    // Proceeding with stale URL if possible
                }
            }
        } catch {
            print("IosFileAccessPlugin: readBookmarkedFile - Failed to resolve bookmark: \(error.localizedDescription)")
            result(FlutterError(code: "BOOKMARK_RESOLUTION_ERROR", message: "Failed to resolve bookmark: \(error.localizedDescription)", details: nil))
            return
        }

        let targetFileUrl = resolvedUrl.appendingPathComponent(relativePath)
        print("IosFileAccessPlugin: readBookmarkedFile - Target file URL: \(targetFileUrl.path)")

        // Try to start access on the base resolved URL first.
        // Bookmarks grant access from the bookmarked URL downwards.
        print("IosFileAccessPlugin: readBookmarkedFile - Attempting to start security access on base URL: \(resolvedUrl.path)")
        guard resolvedUrl.startAccessingSecurityScopedResource() else {
            print("IosFileAccessPlugin: readBookmarkedFile - Failed to start security access on base URL: \(resolvedUrl.path)")
            result(FlutterError(code: "ACCESS_DENIED", message: "Failed to start accessing security-scoped resource for base bookmarked path: \(resolvedUrl.path)", details: nil))
            return
        }
        print("IosFileAccessPlugin: readBookmarkedFile - Successfully started security access on base URL: \(resolvedUrl.path)")

        defer {
            print("IosFileAccessPlugin: readBookmarkedFile - Defer: Stopping security access on base URL: \(resolvedUrl.path)")
            resolvedUrl.stopAccessingSecurityScopedResource()
        }

        do {
            print("IosFileAccessPlugin: readBookmarkedFile - Attempting to read data from: \(targetFileUrl.path)")
            // Check if file exists using FileManager, respecting security scope
            var isTargetFileDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: targetFileUrl.path, isDirectory: &isTargetFileDirectory) {
                if isTargetFileDirectory.boolValue {
                    print("IosFileAccessPlugin: readBookmarkedFile - Error: Target path is a directory, not a file: \(targetFileUrl.path)")
                    result(FlutterError(code: "IS_DIRECTORY", message: "Target path is a directory: \(targetFileUrl.path)", details: nil))
                    return
                }
                print("IosFileAccessPlugin: readBookmarkedFile - File confirmed to exist by FileManager at: \(targetFileUrl.path)")
            } else {
                print("IosFileAccessPlugin: readBookmarkedFile - Error: File does not exist according to FileManager at: \(targetFileUrl.path) (even with scoped access)")
                result(FlutterError(code: "FILE_NOT_FOUND_NATIVE", message: "File not found by native FileManager: \(targetFileUrl.path)", details: nil))
                return
            }

            let fileData = try Data(contentsOf: targetFileUrl)
            print("IosFileAccessPlugin: readBookmarkedFile - Successfully read \(fileData.count) bytes from \(targetFileUrl.path)")
            result(FlutterStandardTypedData(bytes: fileData))
        } catch {
            print("IosFileAccessPlugin: readBookmarkedFile - Failed to read file \(targetFileUrl.path): \(error.localizedDescription)")
            result(FlutterError(code: "FILE_READ_ERROR", message: "Failed to read file \(targetFileUrl.path): \(error.localizedDescription)", details: nil))
        }
    }
} 