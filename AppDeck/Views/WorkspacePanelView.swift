import SwiftUI

struct WorkspacePanelView: View {
    @ObservedObject var store: AppGroupStore
    @ObservedObject var permissions: PermissionManager
    @ObservedObject var viewModel: PreviewGridViewModel
    let onClose: () -> Void

    @State private var isSettingsPresented = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.86)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                header

                if !permissions.screenRecordingGranted || !permissions.accessibilityGranted {
                    PermissionGuideView(permissions: permissions, darkAppearance: true)
                }

                if store.entries.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: 18),
                            count: store.layout.columns
                        ),
                        spacing: 18
                    ) {
                        ForEach(store.entries) { entry in
                            AppPreviewCard(
                                entry: entry,
                                preview: viewModel.previews[entry.id],
                                onTap: {
                                    onClose()
                                    viewModel.activate(entry)
                                }
                            )
                        }
                    }
                    .frame(maxWidth: 1120)
                }

                footer
            }
            .padding(36)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(store: store, permissions: permissions)
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .onExitCommand(perform: onClose)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AppDeck")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("选择一个应用继续工作")
                    .foregroundStyle(.white.opacity(0.64))
            }
            Spacer()
            Text(store.layout.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white.opacity(0.1))
                .clipShape(Capsule())
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.78))
            .accessibilityLabel("打开设置")
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.78))
            .accessibilityLabel("关闭 AppDeck")
        }
        .frame(maxWidth: 1120)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 46))
                .foregroundStyle(.white.opacity(0.55))
            Text("还没有添加应用")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("打开设置，选择你经常使用的 macOS 应用。")
                .foregroundStyle(.white.opacity(0.6))
            Button("打开设置") { isSettingsPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("每 2 秒刷新窗口画面")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Text("Esc 关闭")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: 1120)
    }
}
