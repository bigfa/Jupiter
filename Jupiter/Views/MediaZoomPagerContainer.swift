import SwiftUI
import UIKit

struct MediaZoomPagerContainer<Page: View>: UIViewControllerRepresentable {
    let items: [MediaItem]
    @Binding var selection: Int
    let onReachEnd: (() -> Void)?
    let pageBuilder: (Int, MediaItem) -> Page

    init(
        items: [MediaItem],
        selection: Binding<Int>,
        onReachEnd: (() -> Void)? = nil,
        @ViewBuilder pageBuilder: @escaping (Int, MediaItem) -> Page
    ) {
        self.items = items
        _selection = selection
        self.onReachEnd = onReachEnd
        self.pageBuilder = pageBuilder
    }

    func makeUIViewController(context: Context) -> MediaZoomPageViewController<Page> {
        let controller = MediaZoomPageViewController(
            items: items,
            initialIndex: selection,
            pageBuilder: pageBuilder
        )
        controller.onSelectionChanged = { newIndex in
            DispatchQueue.main.async {
                if selection != newIndex {
                    selection = newIndex
                }
            }
        }
        controller.onReachEnd = onReachEnd
        return controller
    }

    func updateUIViewController(_ uiViewController: MediaZoomPageViewController<Page>, context: Context) {
        uiViewController.onSelectionChanged = { newIndex in
            DispatchQueue.main.async {
                if selection != newIndex {
                    selection = newIndex
                }
            }
        }
        uiViewController.onReachEnd = onReachEnd
        uiViewController.update(
            items: items,
            selectedIndex: selection,
            pageBuilder: pageBuilder
        )
    }
}
