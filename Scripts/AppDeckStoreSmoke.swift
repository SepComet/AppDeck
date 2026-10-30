import Foundation

@main
@MainActor
struct AppDeckStoreSmoke {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppDeckSmoke-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let appURL = root.appendingPathComponent("Example.app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        let info: [String: Any] = [
            "CFBundleIdentifier": "com.example.AppDeckSmoke",
            "CFBundleName": "Example"
        ]
        let infoData = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try infoData.write(to: contentsURL.appendingPathComponent("Info.plist"))

        let storeURL = root.appendingPathComponent("apps.json")
        let store = AppGroupStore(fileURL: storeURL)
        try store.addApplication(at: appURL)
        precondition(store.entries.count == 1)
        precondition(store.entries[0].bundleIdentifier == "com.example.AppDeckSmoke")

        do {
            try store.addApplication(at: appURL)
            fatalError("duplicate application was accepted")
        } catch AppStoreError.duplicateApplication {
            // Expected.
        }

        let reloaded = AppGroupStore(fileURL: storeURL)
        precondition(reloaded.entries == store.entries)
        print("AppDeckStoreSmoke passed")
    }
}
