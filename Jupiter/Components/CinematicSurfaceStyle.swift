import SwiftUI

struct CinematicSurfaceStyle: Equatable {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let shadowRadius: CGFloat
    let foregroundOpacity: Double
    let fillOpacity: Double
    let strokeOpacity: Double
    let shadowOpacity: Double

    static let floatingControl = CinematicSurfaceStyle(
        cornerRadius: 22,
        horizontalPadding: 14,
        verticalPadding: 10,
        shadowRadius: 10,
        foregroundOpacity: 0.88,
        fillOpacity: 0.82,
        strokeOpacity: 0.08,
        shadowOpacity: 0.10
    )

    static let segmentedGroup = CinematicSurfaceStyle(
        cornerRadius: 24,
        horizontalPadding: 4,
        verticalPadding: 4,
        shadowRadius: 10,
        foregroundOpacity: 0.88,
        fillOpacity: 0.76,
        strokeOpacity: 0.08,
        shadowOpacity: 0.10
    )

    static func tab(selected: Bool) -> CinematicSurfaceStyle {
        CinematicSurfaceStyle(
            cornerRadius: 20,
            horizontalPadding: 14,
            verticalPadding: 8,
            shadowRadius: 8,
            foregroundOpacity: selected ? 0.9 : 0.52,
            fillOpacity: selected ? 0.88 : 0,
            strokeOpacity: selected ? 0.08 : 0.03,
            shadowOpacity: selected ? 0.08 : 0
        )
    }
}

enum CinematicPalette {
    static let warmCanvas = Color(red: 0.973, green: 0.962, blue: 0.946)
    static let warmSurface = Color.white
    static let chromeText = Color.black
    static let chromeStroke = Color.black
    static let chromeShadow = Color.black
}

struct CinematicToolbarBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                CinematicPalette.warmCanvas.opacity(0.98),
                Color.white.opacity(0.96)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(CinematicPalette.chromeStroke.opacity(0.06))
                .frame(height: 1)
        }
    }
}
