// The Swift Programming Language
// https://docs.swift.org/swift-book

import AppKit
import UniformTypeIdentifiers


public enum DockPreferencesLoader {
    /// Safely load and decode the Dock preferences.
    /// - Throws: Decoding or file access errors if the plist cannot be read.
    public static func load() throws -> DockPreferences {
        let path = NSString(string: "~/Library/Preferences/com.apple.dock.plist").expandingTildeInPath
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        
        let decoder = PropertyListDecoder()
        return try decoder.decode(DockPreferences.self, from: data)
    }
    
    /// Load the Dock preferences without error handling.
    /// - Warning: Crashes if the plist cannot be read or decoded.
    public static func unsafeLoad() -> DockPreferences {
        return try! self.load()
    }
}


/// Represents the main preferences stored by the Dock.
public struct DockPreferences {
    /// Whether "Recent Applications" should appear in the Dock.
    public let showRecents: Bool
    
    /// Whether the Dock hides automatically.
    public let autohide: Bool
    
    /// Whether running apps show indicator lights below their icons.
    public let showsProcessIndicators: Bool
    
    /// The animation effect used when minimizing windows.
    public let mineffect: MinimizeEffect
    
    /// The position of the Dock on screen (bottom, left, right).
    public let orientation: Orientation
    
    /// Whether the Trash is currently marked as full.
    /// - Note: This key may not always be present in the plist.
    public let trashFull: Bool?
    
    /// The apps pinned to the Dock.
    public let persistentApps: [DockApp]
    
    /// Recently used apps shown in the Dock.
    public let recentApps: [DockApp]
    
    /// Files or folders added to the Dock.
    public let files: [DockFile]
}

extension DockPreferences: Codable {
    enum CodingKeys: String, CodingKey {
        case showRecents = "show-recents"
        case autohide = "autohide"
        case showsProcessIndicators = "show-process-indicators"
        case mineffect = "mineffect"
        case orientation = "orientation"
        case trashFull = "trash-full"
        case persistentApps = "persistent-apps"
        case recentApps = "recent-apps"
        case files = "persistent-others"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showRecents = try container.decode(Bool.self, forKey: .showRecents)
        autohide = try container.decode(Bool.self, forKey: .autohide)
        showsProcessIndicators = try container.decode(Bool.self, forKey: .showsProcessIndicators)
        mineffect = try container.decode(MinimizeEffect.self, forKey: .mineffect)
        orientation = try container.decode(Orientation.self, forKey: .orientation)
        trashFull = try container.decodeIfPresent(Bool.self, forKey: .trashFull) ?? false
        persistentApps = try container.decode([DockApp].self, forKey: .persistentApps)
        recentApps = try container.decode([DockApp].self, forKey: .recentApps)
        files = try container.decode([DockFile].self, forKey: .files)
    }
    
    public enum MinimizeEffect: String, Codable {
        case genie
        case scale
        case suck
        case unknown
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = MinimizeEffect(rawValue: value) ?? .unknown
        }
    }
    
    public enum Orientation: String, Codable {
        case bottom
        case left
        case right
        case unknown
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = Orientation(rawValue: value) ?? .unknown
        }
    }
    

    /// Represents a file reference inside Dock preferences.
    public struct FileData: Codable {
        /// The raw URL string pointing to the file or app.
        /// Stored under `_CFURLString` in the plist.
        let urlString: String
        
        enum CodingKeys: String, CodingKey {
            case urlString = "_CFURLString"
        }
    }
}


extension DockPreferences {
    public static func load() throws -> DockPreferences {
        try DockPreferencesLoader.load()
    }
    
    public static func unsafeLoad() -> DockPreferences {
        DockPreferencesLoader.unsafeLoad()
    }

    /// Opens the Dock preferences pane in the user’s default system preferences.
    public func openDockPreferences() {
        let identifier = "x-apple.systempreferences:com.apple.preference.dock"
        let url = URL(string: identifier)!
        NSWorkspace.shared.open(url)
    }
}


/// Represents an application item in the Dock.
public struct DockApp: Codable {
    /// Metadata associated with the Dock item.
    public let tileData: TileData
    
    enum CodingKeys: String, CodingKey {
        case tileData = "tile-data"
    }
    
    
    public struct TileData: Codable {
        /// The app’s bundle identifier.
        public let bundleIdentifier: String
        
        /// Indicates if this app is marked as a beta build.
        public let isBeta: Bool
        
        /// The label (name) shown in the Dock.
        public let fileLabel: String
        
        /// The file reference for the app.
        internal let fileData: DockPreferences.FileData
        
        /// Returns an url object pointing to the app
        public var fileURL: URL { URL(string: fileData.urlString)! }
        
        
        enum CodingKeys: String, CodingKey {
            case bundleIdentifier = "bundle-identifier"
            case isBeta = "is-beta"
            case fileLabel = "file-label"
            case fileData = "file-data"
        }
    }
    
    /// Returns an `NSImage` object representing the icon of the app.
    public var appIcon: NSImage? {
        return NSWorkspace.shared.icon(forFile: tileData.fileURL.path())
    }
    
    /// Launches the app represented by this item.
    public func launch() {
        NSWorkspace.shared.open(tileData.fileURL)
    }
    
    /// Terminates the app represented by this item. Only if the app is running..
    public func terminate() {
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps where app.bundleIdentifier == tileData.bundleIdentifier {
            app.terminate()
        }
    }
}



/// Represents a file or folder item in the Dock.
public struct DockFile: Codable {
    /// Metadata associated with the Dock item.
    public let tileData: TileData
    
    enum CodingKeys: String, CodingKey {
        case tileData = "tile-data"
    }
    
    public struct TileData: Codable {
        /// The label (name) shown in the Dock.
        public let fileLabel: String
        
        /// The raw file reference.
        private let fileData: DockPreferences.FileData
        
        enum CodingKeys: String, CodingKey {
            case fileLabel = "file-label"
            case fileData = "file-data"
        }
        
        /// Resolved file path from the stored URL string.
        public var filePath: String {
            fileData.urlString
        }
    }
    
    /// Returns an `NSImage` object representing the icon of the file.
    public var fileIcon: NSImage? {
        let url = URL(fileURLWithPath: tileData.filePath)
        let fileExtension = url.pathExtension
        guard let type = UTType.init(filenameExtension: fileExtension) else { return nil }
        
        return NSWorkspace.shared.icon(for: type)
    }
}
