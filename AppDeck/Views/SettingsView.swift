import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: AppGroupStore
    @ObservedObject var permissions: PermissionManager
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        let entries: [AppEntry] = store.entries
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("应用管理")
                        .font(.title2.weight(.semibold))
                    Text("最多添加 6 个应用，卡片顺序会同步到工作台。")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            List {
                ForEach(entries, id: \.bundleIdentifier) { entry in
                    SettingsAppRow(entry: entry) { store.remove(entry) }
                }
                .onMove(perform: store.move)
            }
            .frame(minHeight: 190)

            HStack {
                Button {
                    addApplication()
                } label: {
                    Label("添加应用…", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.entries.count >= 6)

                Spacer()

                Picker("布局", selection: $store.layout) {
                    ForEach(AppLayout.allCases) { layout in
                        Text(layout.title).tag(layout)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }

            PermissionGuideView(permissions: permissions)
        }
        .padding(24)
        .frame(width: 700, height: 540)
        .alert("无法添加应用", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private func addApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.addApplication(at: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SettingsAppRow: View {
    let entry: AppEntry
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: entry.appPath))
                .resizable()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                Text(entry.appPath)
                    .font(.caption)
                    .foregroundStyle(pathIsValid ? Color.secondary : Color.red)
                    .lineLimit(1)
                if !pathIsValid {
                    Text("应用路径已失效，请移除后重新添加。")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
            Spacer()
            Button(role: .destructive, action: onRemove) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    private var pathIsValid: Bool {
        FileManager.default.fileExists(atPath: entry.appPath)
    }
}
