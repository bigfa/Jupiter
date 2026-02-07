import SwiftUI

struct RootTabView: View {
    @State private var selection: RootSection = .home
    @State private var hasAppeared = false
    private let hiddenOffsetRatio: CGFloat = 0.08

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                MediaFeedView(rootSelection: $selection)
                    .opacity(pageOpacity(for: .home))
                    .scaleEffect(pageScale(for: .home))
                    .offset(x: pageOffsetX(for: .home, width: proxy.size.width))
                    .zIndex(pageZIndex(for: .home))
                    .allowsHitTesting(selection == .home)

                AlbumListView(rootSelection: $selection)
                    .opacity(pageOpacity(for: .albums))
                    .scaleEffect(pageScale(for: .albums))
                    .offset(x: pageOffsetX(for: .albums, width: proxy.size.width))
                    .zIndex(pageZIndex(for: .albums))
                    .allowsHitTesting(selection == .albums)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onAppear {
                hasAppeared = true
            }
        }
    }

    private func pageOpacity(for section: RootSection) -> Double {
        selection == section ? 1 : 0
    }

    private func pageScale(for section: RootSection) -> CGFloat {
        selection == section ? 1 : 0.995
    }

    private func pageOffsetX(for section: RootSection, width: CGFloat) -> CGFloat {
        guard selection != section else { return 0 }
        guard hasAppeared else { return 0 }
        let hiddenOffset = width * hiddenOffsetRatio
        return section.order < selection.order ? -hiddenOffset : hiddenOffset
    }

    private func pageZIndex(for section: RootSection) -> Double {
        selection == section ? 1 : 0
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
    }
}
