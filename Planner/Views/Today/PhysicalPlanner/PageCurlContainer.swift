import SwiftUI
import UIKit

// MARK: - Page Curl Container

struct PageCurlContainer<Content: View>: UIViewControllerRepresentable {
    @Binding var currentPageIndex: Int
    let pageRange: ClosedRange<Int>
    let content: (Int) -> Content

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: NSNumber(value: UIPageViewController.SpineLocation.min.rawValue)]
        )
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator
        pageVC.isDoubleSided = false

        // Set initial page
        let initialVC = context.coordinator.makeHostingController(for: currentPageIndex)
        pageVC.setViewControllers([initialVC], direction: .forward, animated: false)

        return pageVC
    }

    func updateUIViewController(_ pageVC: UIPageViewController, context: Context) {
        guard let currentVC = pageVC.viewControllers?.first as? IndexedHostingController<Content>,
              currentVC.pageIndex != currentPageIndex else {
            return
        }

        let direction: UIPageViewController.NavigationDirection = currentPageIndex > currentVC.pageIndex ? .forward : .reverse
        let newVC = context.coordinator.makeHostingController(for: currentPageIndex)
        pageVC.setViewControllers([newVC], direction: direction, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: PageCurlContainer

        init(_ parent: PageCurlContainer) {
            self.parent = parent
        }

        func makeHostingController(for index: Int) -> IndexedHostingController<Content> {
            let view = parent.content(index)
            let hostingVC = IndexedHostingController(rootView: view, pageIndex: index)
            return hostingVC
        }

        // MARK: - Data Source

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let indexedVC = viewController as? IndexedHostingController<Content> else { return nil }
            let previousIndex = indexedVC.pageIndex - 1
            guard parent.pageRange.contains(previousIndex) else { return nil }
            return makeHostingController(for: previousIndex)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let indexedVC = viewController as? IndexedHostingController<Content> else { return nil }
            let nextIndex = indexedVC.pageIndex + 1
            guard parent.pageRange.contains(nextIndex) else { return nil }
            return makeHostingController(for: nextIndex)
        }

        // MARK: - Delegate

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let currentVC = pageViewController.viewControllers?.first as? IndexedHostingController<Content> else {
                return
            }
            parent.currentPageIndex = currentVC.pageIndex
        }
    }
}

// MARK: - Indexed Hosting Controller

final class IndexedHostingController<Content: View>: UIHostingController<Content> {
    let pageIndex: Int

    init(rootView: Content, pageIndex: Int) {
        self.pageIndex = pageIndex
        super.init(rootView: rootView)
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
