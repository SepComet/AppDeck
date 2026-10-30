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
        XCTAssertEqual(AppLayout.twoByTwo.columns, 2)
        XCTAssertEqual(AppLayout.twoByTwo.capacity, 4)
        XCTAssertEqual(AppLayout.twoByThree.columns, 3)
        XCTAssertEqual(AppLayout.twoByThree.capacity, 6)
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
