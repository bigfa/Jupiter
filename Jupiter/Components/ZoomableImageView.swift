import SwiftUI
import UIKit
import Kingfisher

struct ZoomableImageView: UIViewRepresentable {
    let url: URL?
    @Binding var zoomScale: CGFloat
    var dragOffset: CGSize
    var dragScale: CGFloat

    init(url: URL?, zoomScale: Binding<CGFloat> = .constant(1), dragOffset: CGSize = .zero, dragScale: CGFloat = 1.0) {
        self.url = url
        _zoomScale = zoomScale
        self.dragOffset = dragOffset
        self.dragScale = dragScale
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        context.coordinator.imageView = imageView

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        guard let imageView = context.coordinator.imageView else { return }
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            uiView.setZoomScale(1, animated: false)
            zoomScale = 1
        }
        uiView.panGestureRecognizer.isEnabled = uiView.zoomScale > 1.01

        if let url {
            imageView.kf.setImage(with: url)
        } else {
            imageView.image = nil
        }

        // 应用拖动变换到 scrollView
        let translation = CGAffineTransform(translationX: dragOffset.width, y: dragOffset.height)
        let scale = CGAffineTransform(scaleX: dragScale, y: dragScale)
        uiView.transform = translation.concatenating(scale)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?
        var zoomScale: Binding<CGFloat>
        var currentURL: URL?

        init(zoomScale: Binding<CGFloat>) {
            self.zoomScale = zoomScale
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            zoomScale.wrappedValue = scrollView.zoomScale
            scrollView.panGestureRecognizer.isEnabled = scrollView.zoomScale > 1.01
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            zoomScale.wrappedValue = scale
            scrollView.panGestureRecognizer.isEnabled = scale > 1.01
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView else { return }
            if scrollView.zoomScale > 1 {
                scrollView.setZoomScale(1, animated: true)
            } else {
                scrollView.setZoomScale(2, animated: true)
            }
        }
    }
}
