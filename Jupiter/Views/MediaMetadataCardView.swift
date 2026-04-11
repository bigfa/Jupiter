import SwiftUI
import UIKit

struct MediaMetadataCardView<Accessory: View>: UIViewControllerRepresentable {
    let item: MediaItem
    let viewportHeight: CGFloat
    let bottomSafeInset: CGFloat
    let isLoading: Bool
    let statusMessage: String?
    let accessory: Accessory

    init(
        item: MediaItem,
        viewportHeight: CGFloat,
        bottomSafeInset: CGFloat = 0,
        isLoading: Bool = false,
        statusMessage: String? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.item = item
        self.viewportHeight = viewportHeight
        self.bottomSafeInset = bottomSafeInset
        self.isLoading = isLoading
        self.statusMessage = statusMessage
        self.accessory = accessory()
    }

    func makeUIViewController(context: Context) -> MediaMetadataCardHostingController<Accessory> {
        MediaMetadataCardHostingController(
            item: item,
            viewportHeight: viewportHeight,
            bottomSafeInset: bottomSafeInset,
            isLoading: isLoading,
            statusMessage: statusMessage,
            accessory: accessory
        )
    }

    func updateUIViewController(_ uiViewController: MediaMetadataCardHostingController<Accessory>, context: Context) {
        uiViewController.update(
            item: item,
            viewportHeight: viewportHeight,
            bottomSafeInset: bottomSafeInset,
            isLoading: isLoading,
            statusMessage: statusMessage,
            accessory: accessory
        )
    }
}

final class MediaMetadataCardHostingController<Accessory: View>: UIViewController {
    private var hostingController: UIHostingController<MediaFloatingMetadataCard<Accessory>>
    private var heightConstraint: NSLayoutConstraint?

    init(
        item: MediaItem,
        viewportHeight: CGFloat,
        bottomSafeInset: CGFloat,
        isLoading: Bool,
        statusMessage: String?,
        accessory: Accessory
    ) {
        self.hostingController = UIHostingController(
            rootView: MediaFloatingMetadataCard(
                item: item,
                viewportHeight: viewportHeight,
                bottomSafeInset: bottomSafeInset,
                isLoading: isLoading,
                statusMessage: statusMessage
            ) {
                accessory
            }
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        view.addSubview(hostingController.view)

        let height = resolvedHeight(
            item: hostingController.rootView.item,
            viewportHeight: hostingController.rootView.viewportHeight,
            bottomSafeInset: hostingController.rootView.bottomSafeInset,
            isLoading: hostingController.rootView.isLoading
        )

        let heightConstraint = hostingController.view.heightAnchor.constraint(equalToConstant: height)
        self.heightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heightConstraint
        ])

        hostingController.didMove(toParent: self)
    }

    func update(
        item: MediaItem,
        viewportHeight: CGFloat,
        bottomSafeInset: CGFloat,
        isLoading: Bool,
        statusMessage: String?,
        accessory: Accessory
    ) {
        hostingController.rootView = MediaFloatingMetadataCard(
            item: item,
            viewportHeight: viewportHeight,
            bottomSafeInset: bottomSafeInset,
            isLoading: isLoading,
            statusMessage: statusMessage
        ) {
            accessory
        }

        heightConstraint?.constant = resolvedHeight(
            item: item,
            viewportHeight: viewportHeight,
            bottomSafeInset: bottomSafeInset,
            isLoading: isLoading
        )
    }

    private func resolvedHeight(
        item: MediaItem,
        viewportHeight: CGFloat,
        bottomSafeInset: CGFloat,
        isLoading: Bool
    ) -> CGFloat {
        MediaMetadataPresentation.viewerCardHeight(
            for: viewportHeight,
            item: item,
            isDetailLoading: isLoading,
            bottomSafeInset: bottomSafeInset
        )
    }
}
