import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct WorkspacePanelView: View {
    @ObservedObject var store: AppGroupStore
    @ObservedObject var permissions: PermissionManager
    @ObservedObject var viewModel: PreviewGridViewModel
    let onClose: () -> Void

    @State private var isSettingsPresented = false
    @State private var draggedEntryID: String?

    private enum Layout {
        static let topInset: CGFloat = 44
        static let horizontalInset: CGFloat = 52
        static let bottomInset: CGFloat = 28
        static let cardSpacing: CGFloat = 18
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.86)
                .ignoresSafeArea()

            VStack(spacing: Layout.cardSpacing) {
                header

                if !permissions.screenRecordingGranted || !permissions.accessibilityGranted {
                    PermissionGuideView(permissions: permissions, darkAppearance: true)
                }

                if store.entries.isEmpty {
                    emptyState
                } else {
                    GeometryReader { geometry in
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: Layout.cardSpacing),
                                count: store.layout.columns
                            ),
                            spacing: Layout.cardSpacing
                        ) {
                        ForEach(Array(store.entries.enumerated()), id: \.element.id) { index, entry in
                            AppPreviewCard(
                                entry: entry,
                                preview: viewModel.previews[entry.id],
                                shortcutNumber: index + 1,
                                isDragging: draggedEntryID == entry.id,
                                onTap: {
                                    onClose()
                                    viewModel.activate(entry)
                                }
                            )
                            .onDrag {
                                draggedEntryID = entry.id
                                return NSItemProvider(object: entry.id as NSString)
                            }
                            .onDrop(
                                of: [.text],
                                delegate: AppEntryDropDelegate(
                                    targetID: entry.id,
                                    draggedEntryID: $draggedEntryID,
                                    moveEntry: { sourceID, destinationID in
                                        store.move(entryID: sourceID, before: destinationID)
                                    }
                                )
                            )
                        }
                        }
                        .frame(width: gridWidth(for: geometry.size))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                footer
            }
            .padding(.top, Layout.topInset)
            .padding(.horizontal, Layout.horizontalInset)
            .padding(.bottom, Layout.bottomInset)
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
        .frame(maxWidth: .infinity)
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
            Text("1–6 切换应用")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Text("Esc 关闭")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private func gridWidth(for availableSize: CGSize) -> CGFloat {
        let aspectRatio = CGFloat(store.layout.columns) * 1.6 / CGFloat(store.layout.rows)
        return min(availableSize.width, availableSize.height * aspectRatio)
    }
}

private struct AppEntryDropDelegate: DropDelegate {
    let targetID: String
    @Binding var draggedEntryID: String?
    let moveEntry: (String, String) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedEntryID,
              draggedEntryID != targetID else { return }
        moveEntry(draggedEntryID, targetID)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedEntryID = nil
        return true
    }
}
