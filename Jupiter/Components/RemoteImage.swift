import SwiftUI
import Kingfisher
import UIKit

struct RemoteImage: View {
    let url: URL?
    var contentMode: SwiftUI.ContentMode = .fill
    var fadeDuration: Double = 0.2
    var onLoad: (() -> Void)? = nil
    var onImage: ((UIImage) -> Void)? = nil
    var showsProgress: Bool = true
    var disableAnimations: Bool = false

    var body: some View {
        let base = KFImage(url)
            .placeholder {
                if showsProgress {
                    ZStack {
                        Color(.secondarySystemBackground)
                        ProgressView()
                    }
                } else {
                    Color(.secondarySystemBackground)
                }
            }
            .cancelOnDisappear(true)
            .cacheOriginalImage()
            .fade(duration: fadeDuration)
            .resizable()

        if let onLoad {
            base
                .onSuccess { result in
                    if let onImage {
                        onImage(result.image)
                    }
                    onLoad()
                }
                .onFailure { _ in
                    onLoad()
                }
                .modifier(ContentModeModifier(contentMode: contentMode))
                .transaction { transaction in
                    if disableAnimations {
                        transaction.disablesAnimations = true
                        transaction.animation = nil
                    }
                }
        } else {
            base
                .onSuccess { result in
                    if let onImage {
                        onImage(result.image)
                    }
                }
                .modifier(ContentModeModifier(contentMode: contentMode))
                .transaction { transaction in
                    if disableAnimations {
                        transaction.disablesAnimations = true
                        transaction.animation = nil
                    }
                }
        }
    }
}

private struct ContentModeModifier: ViewModifier {
    let contentMode: SwiftUI.ContentMode

    func body(content: Content) -> some View {
        switch contentMode {
        case .fit:
            content.scaledToFit()
        default:
            content.scaledToFill()
        }
    }
}

struct RemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        RemoteImage(url: URL(string: "https://example.com"))
            .frame(width: 120, height: 120)
    }
}
