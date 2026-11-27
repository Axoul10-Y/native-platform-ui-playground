import Flutter
import SwiftUI
import UIKit

/// One navigation bar owns the actions across all four tabs and every pushed page.
final class PlaygroundTabs: UIViewController, UITabBarDelegate {
    private let tabBar = UITabBar()
    private let content = UIView()
    private var pages = [UIViewController]()
    private var selectedIndex = 0
    private var currentPage: UIViewController?
    let library = LibraryController(style: .insetGrouped)
    private let controls: FlutterViewController
    private let bridge: FlutterMethodChannel
    private var groupActions = true
    private lazy var moreItem = barItem("More", "ellipsis", "library.menu")
    private lazy var shareItem: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
        item.identifier = "context.action"
        item.accessibilityLabel = "Share"
        return item
    }()

    init(controls: FlutterViewController) {
        self.controls = controls
        bridge = FlutterMethodChannel(name: "dev.componentstudio/playground",
                                      binaryMessenger: controls.binaryMessenger)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(controls:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        tabBar.delegate = self
        content.translatesAutoresizingMaskIntoConstraints = false
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        view.addSubview(tabBar)
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: view.topAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
        ])
        let catalog = CatalogController()
        let motion = UIHostingController(rootView: MotionLab())
        let entries: [(UIViewController, String, String)] = [
            (library, "Library", "square.stack.3d.up"),
            (controls, "Controls", "switch.2"),
            (catalog, "Catalog", "square.grid.2x2"),
            (motion, "Motion", "waveform.path"),
        ]
        for (page, name, symbol) in entries {
            page.title = name
            page.tabBarItem = UITabBarItem(title: name, image: UIImage(systemName: symbol), tag: 0)
        }
        pages = entries.map { $0.0 }
        tabBar.setItems(pages.map { $0.tabBarItem }, animated: false)
        library.onChange = { [weak self] in self?.updateMenu() }
        library.openItem = { [weak self] id in self?.openItem(id) }
        catalog.openPage = { [weak self] demo in
            guard let self else { return }
            let page: UIViewController
            switch demo {
            case .search: page = SearchController()
            case .scrollBar: page = ScrollingBarController(style: .insetGrouped)
            default: page = UIHostingController(rootView: CatalogPage(demo: demo))
            }
            page.title = demo.title
            decorate(page, largeTitle: demo == .scrollBar)
            navigationController?.pushViewController(page, animated: true)
        }
        bridge.setMethodCallHandler { [weak self] call, reply in
            guard let self else { reply(nil); return }
            switch call.method {
            case "groupToolbar":
                groupActions = call.arguments as? Bool ?? true
                configureBar(animated: true)
            case "openInputs":
                let page = UIHostingController(rootView: CatalogPage(demo: .inputs))
                page.title = Demo.inputs.title
                decorate(page)
                navigationController?.pushViewController(page, animated: true)
            default: reply(FlutterMethodNotImplemented); return
            }
            reply(nil)
        }
        selectPage(0, animated: false)
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = pages.firstIndex(where: { $0.tabBarItem === item }) else { return }
        selectPage(index, animated: true)
    }

    private func selectPage(_ index: Int, animated: Bool) {
        let next = pages[index]
        guard currentPage !== next else { return }
        let previous = currentPage
        let animate = animated && !UIAccessibility.isReduceMotionEnabled
        previous?.willMove(toParent: nil)
        addChild(next)
        next.view.frame = content.bounds
        next.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if animate {
            UIView.transition(with: content, duration: 0.20,
                              options: [.transitionCrossDissolve, .allowUserInteraction, .beginFromCurrentState]) {
                previous?.view.removeFromSuperview()
                self.content.addSubview(next.view)
            }
        } else {
            previous?.view.removeFromSuperview()
            content.addSubview(next.view)
        }
        previous?.removeFromParent()
        next.didMove(toParent: self)
        currentPage = next
        selectedIndex = index
        tabBar.selectedItem = next.tabBarItem
        configureBar(animated: animate)
    }

    private func configureBar(animated: Bool) {
        navigationItem.title = currentPage?.title
        navigationItem.backButtonDisplayMode = .minimal
        let edit = library.editButtonItem
        edit.identifier = "context.action"
        edit.accessibilityIdentifier = "library.edit"
        let leading: [UIBarButtonItem]
        let trailing: [UIBarButtonItem]
        switch selectedIndex {
        case 0: leading = [edit]; trailing = [moreItem]
        case 1 where groupActions: leading = []; trailing = [moreItem, shareItem]
        case 1: leading = [shareItem]; trailing = [moreItem]
        default: leading = []; trailing = [moreItem]
        }
        let animate = animated && !UIAccessibility.isReduceMotionEnabled
        // Detach Share from its old side before assigning it to the other side.
        if leading.contains(shareItem) {
            navigationItem.setRightBarButtonItems(trailing, animated: animate)
            navigationItem.setLeftBarButtonItems(leading, animated: animate)
        } else {
            navigationItem.setLeftBarButtonItems(leading, animated: animate)
            navigationItem.setRightBarButtonItems(trailing, animated: animate)
        }
        updateMenu()
    }

    private func updateMenu() { moreItem.menu = makeMenu(anchor: moreItem) }

    private func barItem(_ label: String, _ symbol: String, _ id: String) -> UIBarButtonItem {
        let item = UIBarButtonItem(image: UIImage(systemName: symbol), style: .plain, target: nil, action: nil)
        item.identifier = id
        item.accessibilityLabel = label
        return item
    }

    private func decorate(_ page: UIViewController, largeTitle: Bool = false) {
        page.navigationItem.largeTitleDisplayMode = largeTitle ? .always : .never
        let item = barItem("More", "ellipsis", "library.menu")
        item.menu = makeMenu(anchor: item)
        page.navigationItem.rightBarButtonItem = item
    }

    private func activateLibrary() {
        navigationController?.popToRootViewController(animated: false)
        selectPage(0, animated: true)
    }

    private func makeMenu(anchor: UIBarButtonItem) -> UIMenu {
        // Resolve state when the menu opens, including from a previously pushed page.
        let deferred = UIDeferredMenuElement.uncached { [weak self, weak anchor] completion in
            guard let self, let anchor else { completion([]); return }
            func action(_ title: String, _ symbol: String, _ handler: @escaping () -> Void) -> UIAction {
                UIAction(title: title, image: UIImage(systemName: symbol)) { _ in handler() }
            }
            let create = action("New Item", "plus") { self.promptForItem() }
            let sort = action("Sort by Name", "textformat.abc") { self.activateLibrary(); self.library.sortItems() }
            let filter = action("Favorites Only", "star") { self.activateLibrary(); self.library.toggleFilter() }
            filter.state = self.library.favoritesOnly ? .on : .off
            let restore = action("Restore Examples", "arrow.counterclockwise") { self.activateLibrary(); self.library.restoreExamples() }
            let share = action("Share List", "square.and.arrow.up") { self.presentShare(anchor: anchor) }
            let delete = UIAction(title: "Delete All Items", image: UIImage(systemName: "trash"),
                                  attributes: .destructive) { _ in self.confirmClear() }
            if self.library.items.isEmpty { delete.attributes.insert(.disabled) }
            completion([create, sort, filter, restore, share,
                        UIMenu(title: "", options: .displayInline, children: [delete])])
        }
        return UIMenu(title: "Library", children: [deferred])
    }

    private var presenter: UIViewController { navigationController?.topViewController ?? self }

    private func promptForItem() {
        let alert = UIAlertController(title: "New Item", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Name"; $0.autocapitalizationType = .sentences }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.activateLibrary()
            self.library.addItem(named: name.isEmpty ? "Untitled" : name)
        })
        presenter.present(alert, animated: true)
    }

    private func confirmClear() {
        let count = library.items.count
        let alert = UIAlertController(title: "Delete all \(count) items?",
                                      message: "Restore Examples brings the sample items back.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { [weak self] _ in
            self?.activateLibrary()
            self?.library.clear()
        })
        presenter.present(alert, animated: true)
    }

    @objc private func share() { presentShare(anchor: shareItem) }

    private func presentShare(anchor: UIBarButtonItem) {
        let names = library.items.map(\.name).joined(separator: "\n")
        let sheet = UIActivityViewController(activityItems: [names.isEmpty ? "My library is empty." : names],
                                             applicationActivities: nil)
        sheet.popoverPresentationController?.barButtonItem = anchor
        presenter.present(sheet, animated: true)
    }

    private func openItem(_ id: UUID) {
        guard let entry = library.items.first(where: { $0.id == id }) else { return }
        let page = ItemController(entry: entry) { [weak self] in self?.library.toggleFavorite(id) }
        decorate(page)
        if let menu = page.navigationItem.rightBarButtonItem {
            page.navigationItem.rightBarButtonItems = [menu, page.favoriteItem]
        }
        navigationController?.pushViewController(page, animated: true)
    }
}
