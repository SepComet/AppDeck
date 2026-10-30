import AppKit
import Combine
import Foundation

enum AppStoreError: LocalizedError, Equatable {
    case invalidApplication
    case duplicateApplication
    case capacityReached

    var errorDescription: String? {
        switch self {
        case .invalidApplication:
            return "所选文件不是可识别的 macOS 应用。"
        case .duplicateApplication:
            return "这个应用已经添加到 AppDeck。"
        case .capacityReached:
            return "最多可以添加 6 个应用。"
        }
    }
}

@MainActor
final class AppGroupStore: ObservableObject {
    @Published private(set) var entries: [AppEntry] = []
    @Published var layout: AppLayout = .one {
        didSet { save() }
    }

    let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let applicationSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.homeDirectoryForCurrentUser
            self.fileURL = applicationSupport
                .appendingPathComponent("AppDeck", isDirectory: true)
                .appendingPathComponent("apps.json")
        }
        load()
    }

    func addApplication(at url: URL) throws {
        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier,
              !bundleIdentifier.isEmpty else {
            throw AppStoreError.invalidApplication
        }
        let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        try addApplication(
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            appPath: url.path
        )
    }

    func addApplication(
        bundleIdentifier: String,
        displayName: String,
        appPath: String
    ) throws {
        guard !bundleIdentifier.isEmpty, !displayName.isEmpty, !appPath.isEmpty else {
            throw AppStoreError.invalidApplication
        }
        guard entries.count < 6 else { throw AppStoreError.capacityReached }
        guard !entries.contains(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            throw AppStoreError.duplicateApplication
        }
        entries.append(
            AppEntry(
                bundleIdentifier: bundleIdentifier,
                displayName: displayName,
                appPath: appPath,
                sortIndex: entries.count
            )
        )
        if entries.count > layout.capacity {
            layout = .forCount(entries.count)
        }
        save()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            entries.remove(at: index)
        }
        normalizeOrder()
        save()
    }

    func setLayout(_ layout: AppLayout) {
        guard entries.count <= layout.capacity else { return }
        self.layout = layout
    }

    func remove(_ entry: AppEntry) {
        entries.removeAll { $0.id == entry.id }
        normalizeOrder()
        save()
    }

    func move(from offsets: IndexSet, to destination: Int) {
        let moving = offsets.sorted().map { entries[$0] }
        for index in offsets.sorted(by: >) {
            entries.remove(at: index)
        }
        let adjustedDestination = destination - offsets.filter { $0 < destination }.count
        entries.insert(contentsOf: moving, at: max(0, min(adjustedDestination, entries.count)))
        normalizeOrder()
        save()
    }

    func reload() {
        load()
    }

    private func normalizeOrder() {
        entries = entries.enumerated().map { index, entry in
            var updated = entry
            updated.sortIndex = index
            return updated
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let saved = try JSONDecoder().decode(PersistedConfiguration.self, from: data)
            entries = saved.entries.sorted { $0.sortIndex < $1.sortIndex }
            layout = saved.layout
            if entries.count > layout.capacity {
                layout = .forCount(entries.count)
            }
            normalizeOrder()
        } catch {
            entries = []
            layout = .one
        }
    }

    private func save() {
        let configuration = PersistedConfiguration(entries: entries, layout: layout)
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(configuration)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("AppDeck could not save configuration: %@", error.localizedDescription)
        }
    }
}

private struct PersistedConfiguration: Codable {
    var entries: [AppEntry]
    var layout: AppLayout
}
