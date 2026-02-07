import SwiftUI

struct FloatingCapsuleButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label

    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                label()
            }
            .font(.subheadline)
            .foregroundStyle(Color.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct FloatingToggleButton: View {
    let current: RootSection
    let onToggle: () -> Void

    var body: some View {
        FloatingCapsuleButton(action: onToggle) {
            Image(systemName: current.toggleIcon)
            Text(current.toggleTitle)
        }
    }
}

struct FloatingTabSwitcher: View {
    @Binding var selection: RootSection
    private let switchAnimation = Animation.easeInOut(duration: 0.28)

    var body: some View {
        HStack(spacing: 2) {
            tabButton(for: .home, title: "照片")
            tabButton(for: .albums, title: "相册")
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
    }

    private func tabButton(for section: RootSection, title: String) -> some View {
        let isSelected = selection == section
        return Button {
            guard selection != section else { return }
            withAnimation(switchAnimation) {
                selection = section
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.black : Color.black.opacity(0.55))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.9) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
