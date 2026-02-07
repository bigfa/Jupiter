import SwiftUI
import UIKit

struct LazyRemoteImage: View {
    let url: URL?
    var contentMode: SwiftUI.ContentMode = .fill
    var aspectRatio: CGFloat?
    var onImageLoaded: ((UIImage) -> Void)? = nil

    @State private var isVisible = false

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio ?? 1, contentMode: .fit)
            .overlay {
                ZStack {
                    Color(.systemGray5)

                    if isVisible {
                        RemoteImage(
                            url: url,
                            contentMode: contentMode,
                            onImage: { image in
                                onImageLoaded?(image)
                            }
                        )
                    }
                }
            }
            .clipped()
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
    }
}

struct LazyRemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        LazyRemoteImage(url: URL(string: "https://example.com"))
            .frame(width: 120, height: 120)
    }
}
