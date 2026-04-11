import Kingfisher
import SwiftUI
import UIKit

struct MediaZoomPhotoView: UIViewControllerRepresentable {
    let url: URL?
    let topInset: CGFloat
    let bottomInset: CGFloat
    @Binding var zoomScale: CGFloat
    @Binding var dragOffset: CGSize
    let metadataState: ViewerMetadataState
    @Binding var isVerticalDragging: Bool
    let onDismissRequested: () -> Void
    let onCollapseMetadataRequested: () -> Void

    func makeUIViewController(context: Context) -> MediaZoomPhotoViewController {
        let controller = MediaZoomPhotoViewController()
        controller.onDismissRequested = onDismissRequested
        controller.onCollapseMetadataRequested = onCollapseMetadataRequested
        controller.zoomScaleBinding = $zoomScale
        controller.dragOffsetBinding = $dragOffset
        controller.isVerticalDraggingBinding = $isVerticalDragging
        controller.configure(
            url: url,
            metadataState: metadataState,
            topInset: topInset,
            bottomInset: bottomInset
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: MediaZoomPhotoViewController, context: Context) {
        uiViewController.onDismissRequested = onDismissRequested
        uiViewController.onCollapseMetadataRequested = onCollapseMetadataRequested
        uiViewController.zoomScaleBinding = $zoomScale
        uiViewController.dragOffsetBinding = $dragOffset
        uiViewController.isVerticalDraggingBinding = $isVerticalDragging
        uiViewController.configure(
            url: url,
            metadataState: metadataState,
            topInset: topInset,
            bottomInset: bottomInset
        )
    }
}

final class MediaZoomPhotoViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    var onDismissRequested: (() -> Void)?
    var onCollapseMetadataRequested: (() -> Void)?
    var zoomScaleBinding: Binding<CGFloat> = .constant(1)
    var dragOffsetBinding: Binding<CGSize> = .constant(.zero)
    var isVerticalDraggingBinding: Binding<Bool> = .constant(false)

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var scrollTopConstraint: NSLayoutConstraint?
    private var scrollBottomConstraint: NSLayoutConstraint?
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(
        target: self,
        action: #selector(handleVerticalPan(_:))
    )

    private var currentURL: URL?
    private var metadataState: ViewerMetadataState = .collapsed
    private var topInset: CGFloat = 0
    private var bottomInset: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupScrollView()
        setupGestures()
        configure(
            url: currentURL,
            metadataState: metadataState,
            topInset: topInset,
            bottomInset: bottomInset
        )
    }

    func configure(url: URL?, metadataState: ViewerMetadataState, topInset: CGFloat, bottomInset: CGFloat) {
        self.metadataState = metadataState
        self.topInset = topInset
        self.bottomInset = bottomInset

        guard isViewLoaded else {
            currentURL = url
            return
        }

        let shouldReloadImage = currentURL != url || imageView.image == nil

        if currentURL != url {
            scrollView.setZoomScale(1, animated: false)
            zoomScaleBinding.wrappedValue = 1
            dragOffsetBinding.wrappedValue = .zero
        }
        currentURL = url

        if shouldReloadImage {
            if let url {
                imageView.kf.setImage(with: url)
            } else {
                imageView.image = nil
            }
        }

        if #available(iOS 17.0, *) {
            let isProUnlocked = UserDefaults.standard.bool(forKey: AppConfig.proEntitlementCacheKey)
            imageView.preferredImageDynamicRange = isProUnlocked ? .high : .standard
        }

        scrollTopConstraint?.constant = topInset
        scrollBottomConstraint?.constant = -bottomInset
        updateScrollInteractionState()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        zoomScaleBinding.wrappedValue = scrollView.zoomScale
        updateScrollInteractionState()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        zoomScaleBinding.wrappedValue = scale
        updateScrollInteractionState()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === panGestureRecognizer else { return true }
        guard scrollView.zoomScale <= 1.01 else { return false }
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }

        let velocity = pan.velocity(in: view)
        guard abs(velocity.y) > abs(velocity.x) else { return false }

        let location = pan.location(in: imageView)
        return displayedImageFrame.contains(location)
    }

    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        let topConstraint = scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: topInset)
        let bottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomInset)
        scrollTopConstraint = topConstraint
        scrollBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topConstraint,
            bottomConstraint,

            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        panGestureRecognizer.delegate = self
        panGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1, animated: true)
            return
        }

        let location = gesture.location(in: imageView)
        let zoomRect = zoomRect(scale: 2, center: location)
        scrollView.zoom(to: zoomRect, animated: true)
    }

    @objc
    private func handleVerticalPan(_ gesture: UIPanGestureRecognizer) {
        guard scrollView.zoomScale <= 1.01 else { return }

        let translationPoint = gesture.translation(in: view)
        let translation = CGSize(width: translationPoint.x, height: translationPoint.y)
        let estimatedPredictedY = translation.height + gesture.velocity(in: view).y * 0.12

        switch gesture.state {
        case .began, .changed:
            isVerticalDraggingBinding.wrappedValue = true
            dragOffsetBinding.wrappedValue = MediaViewerPresentation.photoDragOffset(
                translation: translation,
                metadataState: metadataState
            )
        case .ended, .cancelled, .failed:
            isVerticalDraggingBinding.wrappedValue = false

            if MediaViewerPresentation.photoDragShouldCollapseMetadata(
                translationY: translation.height,
                metadataState: metadataState
            ) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                    dragOffsetBinding.wrappedValue = .zero
                }
                onCollapseMetadataRequested?()
                return
            }

            if MediaViewerPresentation.shouldDismissPhoto(
                translationY: translation.height,
                predictedTranslationY: estimatedPredictedY,
                zoomScale: scrollView.zoomScale,
                metadataState: metadataState
            ) {
                onDismissRequested?()
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    dragOffsetBinding.wrappedValue = .zero
                }
            }
        default:
            break
        }
    }

    private func updateScrollInteractionState() {
        scrollView.panGestureRecognizer.isEnabled = scrollView.zoomScale > 1.01
    }

    private func zoomRect(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale
        zoomRect.origin.x = center.x - zoomRect.size.width / 2
        zoomRect.origin.y = center.y - zoomRect.size.height / 2
        return zoomRect
    }

    private var displayedImageFrame: CGRect {
        guard let image = imageView.image, image.size.width > 0, image.size.height > 0 else {
            return imageView.bounds
        }

        let scale = min(
            imageView.bounds.width / image.size.width,
            imageView.bounds.height / image.size.height
        )
        let fittedSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let origin = CGPoint(
            x: (imageView.bounds.width - fittedSize.width) / 2,
            y: (imageView.bounds.height - fittedSize.height) / 2
        )
        return CGRect(origin: origin, size: fittedSize)
    }
}
