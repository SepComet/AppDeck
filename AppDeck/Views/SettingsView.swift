import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: AppGroupStore
    @ObservedObject var permissions: PermissionManager
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var runningApps: [RunningAppCandidate] = []

    private let runningAppDiscovery = RunningAppDiscovery()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("应用管理")
                        .font(.title2.weight(.semibold))
                    Text("优先从当前正在运行的应用中选择，加入后才会显示在工作台。")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            runningAppsSection
            addedAppsSection
            layoutSection
            PermissionGuideView(permissions: permissions)
        }
        .padding(24)
        .frame(width: 760, height: 720)
        .onAppear(perform: refreshRunningApps)
        .alert("无法添加应用", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private var runningAppsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("当前运行中的应用")
                        .font(.headline)
                    Text("点击添加后才会进入白名单，最多 6 个。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    refreshRunningApps()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }

            if runningApps.isEmpty {
                Text("暂时没有可添加的运行中应用。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 72)
            } else {
                List(runningApps) { candidate in
                    RunningAppRow(
                        candidate: candidate,
                        isAdded: isAdded(candidate),
                        isFull: store.entries.count >= 6,
                        onAdd: { addRunningApplication(candidate) }
                    )
                }
                .listStyle(.inset)
                .frame(height: 170)
            }
        }
    }

    private var addedAppsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("展示白名单")
                    .font(.headline)
                Spacer()
                Button {
                    addApplicationFromDisk()
                } label: {
                    Label("从文件选择…", systemImage: "folder")
                }
                .buttonStyle(.borderless)
                .disabled(store.entries.count >= 6)
            }

            if store.entries.isEmpty {
                Text("还没有加入应用。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                List {
                    ForEach(store.entries) { entry in
                        SettingsAppRow(entry: entry) { store.remove(entry) }
                    }
                    .onMove(perform: store.move)
                }
                .listStyle(.inset)
                .frame(height: 150)
            }
        }
    }

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("布局预设")
                    .font(.headline)
                Spacer()
                Text("当前 \(store.entries.count) 个应用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(AppLayout.allCases) { layout in
                    Button {
                        store.setLayout(layout)
                    } label: {
                        VStack(spacing: 3) {
                            Text("\(layout.capacity) 个")
                                .font(.subheadline.weight(.semibold))
                            Text("\(layout.columns) × \(layout.rows)")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(store.layout == layout ? .accentColor : .secondary)
                    .disabled(store.entries.count > layout.capacity)
                }
            }
        }
    }

    private func refreshRunningApps() {
        runningApps = runningAppDiscovery.candidates()
    }

    private func isAdded(_ candidate: RunningAppCandidate) -> Bool {
        store.entries.contains { $0.bundleIdentifier == candidate.bundleIdentifier }
    }

    private func addRunningApplication(_ candidate: RunningAppCandidate) {
        do {
            try store.addApplication(
                bundleIdentifier: candidate.bundleIdentifier,
                displayName: candidate.displayName,
                appPath: candidate.appPath
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addApplicationFromDisk() {
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

private struct RunningAppRow: View {
    let candidate: RunningAppCandidate
    let isAdded: Bool
    let isFull: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: candidate.appPath))
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(candidate.displayName)
                    if candidate.isActive {
                        Text("当前")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tint)
                    }
                }
                Text(candidate.appPath)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button(isAdded ? "已添加" : "添加", action: onAdd)
                .buttonStyle(.bordered)
                .disabled(isAdded || isFull)
        }
        .padding(.vertical, 2)
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
