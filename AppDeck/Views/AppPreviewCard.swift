import AppKit
import SwiftUI

struct AppPreviewCard: View {
    let entry: AppEntry
    let preview: AppPreview?
    let shortcutNumber: Int
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                previewImage
                    .aspectRatio(1.6, contentMode: .fit)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack {
                    HStack {
                        Text("\(shortcutNumber)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(.black.opacity(0.58), in: Circle())
                            .padding(10)
                        Spacer()
                    }
                    Spacer()
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 38, height: 38)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .padding(8)
                            .background(.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .padding(10)
                    }
                }

            }
            .frame(maxWidth: .infinity)
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
        .accessibilityLabel("按 \(shortcutNumber) 切换到 \(entry.displayName)")
    }

    @ViewBuilder
    private var previewImage: some View {
        if let image = preview?.image {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .background(Color.black.opacity(0.25))
        } else {
            Image(nsImage: appIcon)
                .resizable()
                .frame(width: 52, height: 52)
                .opacity(0.82)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var appIcon: NSImage {
        NSWorkspace.shared.icon(forFile: entry.appPath)
    }

}
