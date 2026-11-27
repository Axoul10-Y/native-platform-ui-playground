import UIKit

struct Entry: Codable, Equatable {
    var id = UUID()
    var name: String
    var symbol: String
    var note: String
    var favorite = false

    static func examples() -> [Entry] {
        [
            Entry(name: "Coastal Drive", symbol: "car", note: "A route along the coast.", favorite: true),
            Entry(name: "City Walk", symbol: "figure.walk", note: "Places to explore on foot."),
            Entry(name: "Field Notes", symbol: "book", note: "Observations from the last trip."),
            Entry(name: "Lookout Point", symbol: "binoculars", note: "A stop with a view.", favorite: true),
            Entry(name: "Weekend Plan", symbol: "calendar", note: "Ideas for a free afternoon."),
        ]
    }
}

final class LibraryController: UITableViewController {
    private let defaultsKey = "componentstudio.library.v1"
    private(set) var items = [Entry]()
    private(set) var favoritesOnly = false
    var onChange: (() -> Void)?
    var openItem: ((UUID) -> Void)?
    private var visible: [Entry] { favoritesOnly ? items.filter(\.favorite) : items }

    override init(style: UITableView.Style) {
        super.init(style: style)
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let stored = try? JSONDecoder().decode([Entry].self, from: data) { items = stored }
        else { items = Entry.examples() }
    }
    required init?(coder: NSCoder) { fatalError("Use init(style:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "item")
        tableView.accessibilityIdentifier = "library.list"
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshSavedItems), for: .valueChanged)
        refreshControl = refresh
        updateEmptyState()
    }

    @objc private func refreshSavedItems() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let stored = try? JSONDecoder().decode([Entry].self, from: data) { items = stored }
        tableView.reloadData()
        updateEmptyState()
        refreshControl?.endRefreshing()
        onChange?()
    }

    private func updateEmptyState() {
        if visible.isEmpty {
            var state = UIContentUnavailableConfiguration.empty()
            state.image = UIImage(systemName: favoritesOnly ? "star" : "tray")
            state.text = favoritesOnly ? "No Favorites" : "No Items"
            state.secondaryText = favoritesOnly ? "Turn off Favorites Only in the menu to see every item." : "Open the menu to add an item or restore the examples."
            contentUnavailableConfiguration = state
        } else { contentUnavailableConfiguration = nil }
    }

    private func changed(reload: Bool = true) {
        if let data = try? JSONEncoder().encode(items) { UserDefaults.standard.set(data, forKey: defaultsKey) }
        if isViewLoaded {
            if reload { tableView.reloadData() }
            updateEmptyState()
        }
        onChange?()
    }

    func clear() { items.removeAll(); changed() }
    func addItem(named name: String) {
        favoritesOnly = false
        items.append(Entry(name: name, symbol: "bookmark", note: "Added to your playground library."))
        changed()
    }
    func sortItems() { items.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }; changed() }
    func toggleFilter() { favoritesOnly.toggle(); changed() }
    func toggleFavorite(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].favorite.toggle()
        changed()
    }
    func restoreExamples() {
        favoritesOnly = false
        // Only add missing samples. Keep the user's entries and favorite choices.
        for example in Entry.examples() where !items.contains(where: { $0.name == example.name }) {
            items.append(example)
        }
        changed()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { visible.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        visible.isEmpty ? nil : (favoritesOnly ? "Favorites" : "Saved items")
    }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        visible.isEmpty ? nil : "Edit to delete or reorder. Touch and hold an item for more actions."
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = visible[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = entry.name
        content.secondaryText = entry.note
        content.image = UIImage(systemName: entry.symbol)
        content.imageProperties.tintColor = .systemBlue
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityValue = entry.favorite ? "Favorite" : nil
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openItem?(visible[indexPath.row].id)
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        remove(visible[indexPath.row].id)
    }
    private func remove(_ id: UUID) {
        guard let row = visible.firstIndex(where: { $0.id == id }) else { return }
        items.removeAll { $0.id == id }
        tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
        changed(reload: false)
    }
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { !favoritesOnly }
    override func tableView(_ tableView: UITableView, moveRowAt source: IndexPath, to destination: IndexPath) {
        let moved = items.remove(at: source.row)
        items.insert(moved, at: destination.row)
        changed(reload: false)
    }
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt path: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        let entry = visible[path.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let star = UIAction(title: entry.favorite ? "Remove Favorite" : "Favorite",
                                image: UIImage(systemName: entry.favorite ? "star.slash" : "star")) { _ in
                self?.toggleFavorite(entry.id)
            }
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self?.remove(entry.id)
            }
            return UIMenu(children: [star, delete])
        }
    }
}

final class ItemController: UIViewController {
    private var entry: Entry
    private let onFavorite: () -> Void
    lazy var favoriteItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(toggle))
        item.identifier = "context.action"
        return item
    }()
    init(entry: Entry, onFavorite: @escaping () -> Void) {
        self.entry = entry
        self.onFavorite = onFavorite
        super.init(nibName: nil, bundle: nil)
        title = entry.name
        updateFavorite()
    }
    required init?(coder: NSCoder) { fatalError("Use init(entry:onFavorite:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: entry.symbol)
        configuration.text = entry.name
        configuration.secondaryText = entry.note
        contentUnavailableConfiguration = configuration
    }
    private func updateFavorite() {
        favoriteItem.image = UIImage(systemName: entry.favorite ? "star.fill" : "star")
        favoriteItem.accessibilityLabel = entry.favorite ? "Remove Favorite" : "Favorite"
    }
    @objc private func toggle() {
        entry.favorite.toggle()
        onFavorite()
        updateFavorite()
        if !UIAccessibility.isReduceMotionEnabled { favoriteItem.addSymbolEffect(.bounce) }
    }
}
