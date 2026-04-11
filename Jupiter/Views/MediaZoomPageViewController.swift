import SwiftUI
import UIKit

final class MediaZoomPageViewController<Page: View>: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    typealias PageBuilder = (Int, MediaItem) -> Page

    var onSelectionChanged: ((Int) -> Void)?
    var onReachEnd: (() -> Void)?

    private var items: [MediaItem]
    private var pageBuilder: PageBuilder
    private var currentIndex: Int

    init(
        items: [MediaItem],
        initialIndex: Int,
        pageBuilder: @escaping PageBuilder
    ) {
        self.items = items
        self.pageBuilder = pageBuilder
        self.currentIndex = max(0, min(initialIndex, max(items.count - 1, 0)))
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        view.backgroundColor = .clear

        scrollView?.backgroundColor = .clear
        scrollView?.showsHorizontalScrollIndicator = false

        guard let initialController = makeController(for: currentIndex) else { return }
        setViewControllers([initialController], direction: .forward, animated: false)
    }

    func update(
        items: [MediaItem],
        selectedIndex: Int,
        pageBuilder: @escaping PageBuilder
    ) {
        self.items = items
        self.pageBuilder = pageBuilder

        guard !items.isEmpty else { return }

        let clampedIndex = max(0, min(selectedIndex, items.count - 1))
        let visibleController = viewControllers?.first as? IndexedHostingController<Page>

        if visibleController?.index == clampedIndex {
            visibleController?.rootView = pageBuilder(clampedIndex, items[clampedIndex])
            currentIndex = clampedIndex
            return
        }

        guard let targetController = makeController(for: clampedIndex) else { return }
        let direction: NavigationDirection = clampedIndex >= currentIndex ? .forward : .reverse
        currentIndex = clampedIndex
        setViewControllers([targetController], direction: direction, animated: false)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let hosted = viewController as? IndexedHostingController<Page>,
              let previousIndex = MediaViewerPresentation.neighboringIndex(
                currentIndex: hosted.index,
                direction: .previous,
                itemCount: items.count
              ) else {
            return nil
        }
        return makeController(for: previousIndex)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let hosted = viewController as? IndexedHostingController<Page>,
              let nextIndex = MediaViewerPresentation.neighboringIndex(
                currentIndex: hosted.index,
                direction: .next,
                itemCount: items.count
              ) else {
            return nil
        }
        return makeController(for: nextIndex)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let hosted = viewControllers?.first as? IndexedHostingController<Page> else {
            return
        }

        currentIndex = hosted.index
        onSelectionChanged?(hosted.index)

        if MediaViewerPresentation.shouldRequestMore(
            afterSelecting: hosted.index,
            itemCount: items.count
        ) {
            onReachEnd?()
        }
    }

    private func makeController(for index: Int) -> IndexedHostingController<Page>? {
        guard items.indices.contains(index) else { return nil }
        let controller = IndexedHostingController(
            index: index,
            rootView: pageBuilder(index, items[index])
        )
        controller.view.backgroundColor = .clear
        return controller
    }

    private var scrollView: UIScrollView? {
        view.subviews.first { $0 is UIScrollView } as? UIScrollView
    }
}

private final class IndexedHostingController<Page: View>: UIHostingController<Page> {
    let index: Int

    init(index: Int, rootView: Page) {
        self.index = index
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
