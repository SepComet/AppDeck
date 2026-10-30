import Foundation
import XCTest
@testable import AppDeck

@MainActor
final class AppGroupStoreTests: XCTestCase {
    func testApplicationListPersistsAndRejectsDuplicates() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppDeckTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let appURL = try makeApplication(
            in: root,
            bundleIdentifier: "com.example.AppDeckTestApp",
            name: "Example"
        )

        let store = AppGroupStore(fileURL: root.appendingPathComponent("apps.json"))
        try store.addApplication(at: appURL)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.bundleIdentifier, "com.example.AppDeckTestApp")

        XCTAssertThrowsError(try store.addApplication(at: appURL)) { error in
            XCTAssertEqual(error as? AppStoreError, .duplicateApplication)
        }

        let reloadedStore = AppGroupStore(fileURL: root.appendingPathComponent("apps.json"))
        XCTAssertEqual(reloadedStore.entries, store.entries)
    }

    func testOrderingAndCapacityLimit() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppDeckTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = AppGroupStore(fileURL: root.appendingPathComponent("apps.json"))
        for index in 0..<6 {
            let appURL = try makeApplication(
                in: root,
                bundleIdentifier: "com.example.AppDeckTestApp\(index)",
                name: "Example \(index)"
            )
            try store.addApplication(at: appURL)
        }

        XCTAssertEqual(store.entries.count, 6)
        XCTAssertEqual(store.layout, .twoByThree)

        store.move(from: IndexSet(integer: 0), to: store.entries.count)
        XCTAssertEqual(store.entries.last?.bundleIdentifier, "com.example.AppDeckTestApp0")
        XCTAssertEqual(store.entries.map(\.sortIndex), Array(0..<6))

        let seventhApp = try makeApplication(
            in: root,
            bundleIdentifier: "com.example.AppDeckTestApp6",
            name: "Example 6"
        )
        XCTAssertThrowsError(try store.addApplication(at: seventhApp)) { error in
            XCTAssertEqual(error as? AppStoreError, .capacityReached)
        }
    }

    func testLayoutCapacityAndColumns() {
        let expected: [(AppLayout, Int, Int, Int)] = [
            (.one, 1, 1, 1),
            (.two, 2, 2, 1),
            (.three, 3, 3, 1),
            (.four, 4, 2, 2),
            (.five, 5, 3, 2),
            (.six, 6, 3, 2)
        ]

        for (layout, capacity, columns, rows) in expected {
            XCTAssertEqual(layout.capacity, capacity)
            XCTAssertEqual(layout.columns, columns)
            XCTAssertEqual(layout.rows, rows)
        }
        XCTAssertEqual(AppLayout.twoByTwo, .four)
        XCTAssertEqual(AppLayout.twoByThree, .six)
    }

    func testAddingApplicationMetadataFromRunningAppIsPersisted() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppDeckTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = AppGroupStore(fileURL: root.appendingPathComponent("apps.json"))
        try store.addApplication(
            bundleIdentifier: "com.example.RunningApp",
            displayName: "Running App",
            appPath: "/Applications/Running App.app"
        )

        XCTAssertEqual(store.entries.first?.displayName, "Running App")
        XCTAssertEqual(store.entries.first?.appPath, "/Applications/Running App.app")
        XCTAssertEqual(store.layout, .one)

        let reloadedStore = AppGroupStore(fileURL: root.appendingPathComponent("apps.json"))
        XCTAssertEqual(reloadedStore.entries, store.entries)
    }

    func testLegacyLayoutValuesDecodeToNewPresets() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppDeckTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let configuration = #"{"entries":[],"layout":"twoByThree"}"#.data(using: .utf8)!
        let fileURL = root.appendingPathComponent("apps.json")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try configuration.write(to: fileURL)

        let store = AppGroupStore(fileURL: fileURL)
        XCTAssertEqual(store.layout, .six)
    }

    private func makeApplication(
        in root: URL,
        bundleIdentifier: String,
        name: String
    ) throws -> URL {
        let appURL = root.appendingPathComponent("\(name).app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        let info: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleName": name
        ]
        let infoData = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try infoData.write(to: contentsURL.appendingPathComponent("Info.plist"))
        return appURL
    }
}
