import Foundation
import Combine

// MARK: - Storage Engine

final class StorageEngine: ObservableObject {
    @Published var applications: [AppStorageInfo] = []
    @Published var largeFiles: [FileStorageInfo] = []
    @Published var homeDirectories: [DirectoryStorageInfo] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var totalAppsSize: UInt64 = 0

    private let fileManager = FileManager.default

    // MARK: - Scan All

    func scanAll() {
        guard !isScanning else { return }
        isScanning = true
        scanProgress = 0

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            self.performScanApplications()
            DispatchQueue.main.async { self.scanProgress = 0.33 }

            self.performScanHomeDirectories()
            DispatchQueue.main.async { self.scanProgress = 0.66 }

            self.performScanLargeFiles()
            DispatchQueue.main.async {
                self.scanProgress = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isScanning = false
                }
            }
        }
    }

    // MARK: - Scan Applications

    private func performScanApplications() {
        let appsPath = "/Applications"
        guard let contents = try? fileManager.contentsOfDirectory(atPath: appsPath) else { return }

        var apps: [AppStorageInfo] = []
        var total: UInt64 = 0

        for item in contents where item.hasSuffix(".app") {
            let fullPath = "\(appsPath)/\(item)"
            let size = directorySize(at: fullPath)
            let name = (item as NSString).deletingPathExtension
            let bundleID = Bundle(path: fullPath)?.bundleIdentifier ?? ""
            apps.append(AppStorageInfo(name: name, bundleID: bundleID, path: fullPath, size: size))
            total += size
        }

        apps.sort { $0.size > $1.size }

        DispatchQueue.main.async { [weak self] in
            self?.applications = apps
            self?.totalAppsSize = total
        }
    }

    // MARK: - Scan Home Directories

    private func performScanHomeDirectories() {
        let homePath = NSHomeDirectory()
        let keyDirs = ["Desktop", "Documents", "Downloads", "Movies", "Music", "Pictures", "Library"]

        var dirs: [DirectoryStorageInfo] = []

        for dir in keyDirs {
            let fullPath = "\(homePath)/\(dir)"
            guard fileManager.fileExists(atPath: fullPath) else { continue }
            let size = directorySize(at: fullPath)
            let count = (try? fileManager.contentsOfDirectory(atPath: fullPath))?.count ?? 0
            dirs.append(DirectoryStorageInfo(name: dir, path: fullPath, size: size, itemCount: count))
        }

        dirs.sort { $0.size > $1.size }

        DispatchQueue.main.async { [weak self] in
            self?.homeDirectories = dirs
        }
    }

    // MARK: - Scan Large Files

    private func performScanLargeFiles() {
        let homePath = NSHomeDirectory()
        var files: [FileStorageInfo] = []
        let minSize: UInt64 = 50_000_000 // 50 MB

        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: homePath),
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        var scanned = 0
        while let url = enumerator.nextObject() as? URL {
            scanned += 1
            if scanned > 80000 { break }

            guard let rv = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey]),
                  rv.isRegularFile == true,
                  let size = rv.fileSize, UInt64(size) >= minSize else { continue }

            files.append(FileStorageInfo(
                name: url.lastPathComponent,
                path: url.path,
                size: UInt64(size),
                fileExtension: url.pathExtension,
                modificationDate: rv.contentModificationDate
            ))
        }

        files.sort { $0.size > $1.size }

        DispatchQueue.main.async { [weak self] in
            self?.largeFiles = Array(files.prefix(50))
        }
    }

    // MARK: - Helpers

    private func directorySize(at path: String) -> UInt64 {
        var total: UInt64 = 0

        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        while let url = enumerator.nextObject() as? URL {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += UInt64(size)
            }
        }
        return total
    }
}
