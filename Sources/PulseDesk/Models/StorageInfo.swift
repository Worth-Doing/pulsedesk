import Foundation

// MARK: - App Storage Info

struct AppStorageInfo: Identifiable {
    let id = UUID()
    let name: String
    let bundleID: String
    let path: String
    let size: UInt64
}

// MARK: - File Storage Info

struct FileStorageInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: UInt64
    let fileExtension: String
    let modificationDate: Date?
}

// MARK: - Directory Storage Info

struct DirectoryStorageInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: UInt64
    let itemCount: Int

    var icon: String {
        switch name {
        case "Desktop": return "desktopcomputer"
        case "Documents": return "doc.fill"
        case "Downloads": return "arrow.down.circle.fill"
        case "Movies": return "film.fill"
        case "Music": return "music.note"
        case "Pictures": return "photo.fill"
        case "Library": return "books.vertical.fill"
        default: return "folder.fill"
        }
    }
}
