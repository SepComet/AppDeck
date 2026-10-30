import AppKit
import SwiftUI

struct AppPreviewCard: View {
    let entry: AppEntry
    let preview: AppPreview?
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                previewImage
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.6, contentMode: .fit)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: 10) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(statusLabel)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(14)
            .background(.white.opacity(isHovered ? 0.16 : 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(isHovered ? 0.3 : 0.12), lineWidth: 1)
            }
            .scaleEffect(isHovered ? 1.015 : 1)
            .animation(.easeOut(duration: 0.16), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel("切换到 \(entry.displayName)")
    }

    @ViewBuilder
    private var previewImage: some View {
        if let image = preview?.image, preview?.status == .ready {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .background(Color.black.opacity(0.25))
        } else {
            VStack(spacing: 10) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 52, height: 52)
                    .opacity(0.82)
                Text(statusLabel)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var appIcon: NSImage {
        NSWorkspace.shared.icon(forFile: entry.appPath)
    }

    private var statusLabel: String {
        if !FileManager.default.fileExists(atPath: entry.appPath) {
            return "应用路径已失效"
        }
        switch preview?.status {
        case .ready:
            return "已捕获窗口"
        case .loading:
            return "正在刷新…"
        case .notRunning:
            return "未运行"
        case .screenRecordingRequired:
            return "需要屏幕录制权限"
        case .captureFailed:
            return "截图不可用"
        case .unavailable, .none:
            return "等待窗口"
        }
    }
}
