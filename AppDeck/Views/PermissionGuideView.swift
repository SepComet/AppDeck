import SwiftUI

struct PermissionGuideView: View {
    @ObservedObject var permissions: PermissionManager
    var darkAppearance = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("需要系统权限才能显示完整预览", systemImage: "lock.shield")
                .font(.headline)
                .foregroundStyle(primaryColor)

            HStack(spacing: 18) {
                PermissionRow(
                    title: "屏幕录制",
                    detail: permissions.screenRecordingGranted ? "已授权" : "用于获取窗口画面",
                    granted: permissions.screenRecordingGranted,
                    actionTitle: permissions.screenRecordingGranted ? "已授权" : "打开设置",
                    darkAppearance: darkAppearance,
                    action: {
                        if permissions.screenRecordingGranted {
                            permissions.refresh()
                        } else {
                            permissions.openScreenRecordingSettings()
                        }
                    }
                )

                PermissionRow(
                    title: "辅助功能",
                    detail: permissions.accessibilityGranted ? "已授权" : "用于精确提升目标窗口",
                    granted: permissions.accessibilityGranted,
                    actionTitle: permissions.accessibilityGranted ? "已授权" : "打开设置",
                    darkAppearance: darkAppearance,
                    action: {
                        if permissions.accessibilityGranted {
                            permissions.refresh()
                        } else {
                            permissions.openAccessibilitySettings()
                        }
                    }
                )

                Button("重新检测") {
                    permissions.refresh()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .foregroundStyle(primaryColor)
    }

    private var primaryColor: Color {
        isDark ? .white : .primary
    }

    private var isDark: Bool {
        darkAppearance || colorScheme == .dark
    }
}

private struct PermissionRow: View {
    let title: String
    let detail: String
    let granted: Bool
    let actionTitle: String
    let darkAppearance: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(granted ? .green : .yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryColor)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(secondaryColor)
            }
            Button(actionTitle, action: action)
                .buttonStyle(.borderless)
                .foregroundStyle(primaryColor.opacity(0.82))
                .disabled(granted)
        }
    }

    private var primaryColor: Color {
        isDark ? .white : .primary
    }

    private var secondaryColor: Color {
        isDark ? .white.opacity(0.64) : .secondary
    }

    private var isDark: Bool {
        darkAppearance || colorScheme == .dark
    }
}
