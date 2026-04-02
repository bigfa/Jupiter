import SwiftUI

struct FloatingCapsuleButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label

    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }

    var body: some View {
        let style = CinematicSurfaceStyle.floatingControl
        Button(action: action) {
            HStack(spacing: 6) {
                label()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(CinematicPalette.chromeText.opacity(style.foregroundOpacity))
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .background {
                Capsule(style: .continuous)
                    .fill(CinematicPalette.warmSurface.opacity(style.fillOpacity))
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(CinematicPalette.chromeStroke.opacity(style.strokeOpacity), lineWidth: 1)
            }
            .shadow(
                color: CinematicPalette.chromeShadow.opacity(style.shadowOpacity),
                radius: style.shadowRadius,
                x: 0,
                y: 6
            )
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
        let containerStyle = CinematicSurfaceStyle.segmentedGroup
        HStack(spacing: 2) {
            tabButton(for: .home, title: String(localized: "Photos"))
            tabButton(for: .albums, title: String(localized: "Albums"))
        }
        .padding(.horizontal, containerStyle.horizontalPadding)
        .padding(.vertical, containerStyle.verticalPadding)
        .background {
            Capsule(style: .continuous)
                .fill(CinematicPalette.warmSurface.opacity(containerStyle.fillOpacity))
        }
        .overlay {
            Capsule(style: .continuous)
                .stroke(CinematicPalette.chromeStroke.opacity(containerStyle.strokeOpacity), lineWidth: 1)
        }
        .shadow(
            color: CinematicPalette.chromeShadow.opacity(containerStyle.shadowOpacity),
            radius: containerStyle.shadowRadius,
            x: 0,
            y: 6
        )
    }

    private func tabButton(for section: RootSection, title: String) -> some View {
        let isSelected = selection == section
        let style = CinematicSurfaceStyle.tab(selected: isSelected)
        return Button {
            guard selection != section else { return }
            withAnimation(switchAnimation) {
                selection = section
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(CinematicPalette.chromeText.opacity(style.foregroundOpacity))
                .padding(.horizontal, style.horizontalPadding)
                .padding(.vertical, style.verticalPadding)
                .background(
                    Capsule(style: .continuous)
                        .fill(CinematicPalette.warmSurface.opacity(style.fillOpacity))
                )
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(CinematicPalette.chromeStroke.opacity(style.strokeOpacity), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
