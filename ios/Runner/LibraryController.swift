import UIKit

struct Entry: Codable, Equatable {
    var id = UUID()
    var name: String
    var symbol: String
    var note: String
    var favorite = false
    var archived: Bool? // Absent in entries saved by the first playground.
    var isArchived: Bool { archived == true }

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
    private let storage: UserDefaults
    private(set) var items = [Entry]()
    private(set) var favoritesOnly = false
    private(set) var showingArchive = false
    private(set) var selecting = false
    private(set) var selectedIDs = Set<UUID>()
    var scopedItems: [Entry] { items.filter { $0.isArchived == showingArchive } }
    var hasVisibleItems: Bool { !visible.isEmpty }
    var selectedItems: [Entry] { visible.filter { selectedIDs.contains($0.id) } }
    private var visible: [Entry] { favoritesOnly ? scopedItems.filter(\.favorite) : scopedItems }
    var onChange: (() -> Void)?
    var onSelectionChange: (() -> Void)?
    var openItem: ((UUID) -> Void)?

    private let scope = UISegmentedControl(items: ["Saved", "Archive"])

    init(style: UITableView.Style, storage: UserDefaults = .standard) {
        self.storage = storage
        super.init(style: style)
        if let data = storage.data(forKey: defaultsKey),
           let stored = try? JSONDecoder().decode([Entry].self, from: data) { items = stored }
        else { items = Entry.examples() }
    }
    required init?(coder: NSCoder) { fatalError("Use init(style:storage:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "item")
        tableView.accessibilityIdentifier = "library.list"
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshSavedItems), for: .valueChanged)
        refreshControl = refresh
        scope.selectedSegmentIndex = 0
        scope.addTarget(self, action: #selector(scopeChanged), for: .valueChanged)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 52))
        header.addSubview(scope)
        scope.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scope.leadingAnchor.constraint(equalTo: header.layoutMarginsGuide.leadingAnchor),
            scope.trailingAnchor.constraint(equalTo: header.layoutMarginsGuide.trailingAnchor),
            scope.centerYAnchor.constraint(equalTo: header.centerYAnchor),
        ])
        tableView.tableHeaderView = header
        refreshUI()
    }

    @objc private func refreshSavedItems() {
        if let data = storage.data(forKey: defaultsKey),
           let stored = try? JSONDecoder().decode([Entry].self, from: data), stored != items {
            items = stored
        }
        refreshUI()
        refreshControl?.endRefreshing()
    }

    @objc private func scopeChanged() { setArchiveScope(scope.selectedSegmentIndex == 1) }
    func setArchiveScope(_ archived: Bool) {
        if selecting { setSelecting(false) }
        showingArchive = archived
        scope.selectedSegmentIndex = archived ? 1 : 0
        refreshUI()
    }

    func setSelecting(_ enabled: Bool) {
        guard enabled != selecting else { return }
        if enabled && isEditing { setEditing(false, animated: false) }
        selecting = enabled
        selectedIDs.removeAll()
        tableView.allowsMultipleSelectionDuringEditing = enabled
        setEditing(enabled, animated: true)
        scope.isEnabled = !enabled
        refreshUI(reload: false)
        if !enabled { onSelectionChange?() }
    }

    private func refreshUI(reload: Bool = true) {
        if isViewLoaded {
            selectedIDs.formIntersection(visible.map(\.id))
            if reload {
                tableView.reloadData()
                if selecting {
                    for (row, entry) in visible.enumerated() where selectedIDs.contains(entry.id) {
                        tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
                    }
                }
            }
            if visible.isEmpty {
                var state = UIContentUnavailableConfiguration.empty()
                state.image = UIImage(systemName: favoritesOnly ? "star" : (showingArchive ? "archivebox" : "tray"))
                state.text = favoritesOnly ? "No Favorites" : (showingArchive ? "Archive is empty" : "No Items")
                state.secondaryText = favoritesOnly ? "Turn off Favorites Only in the menu to see every item."
                    : (showingArchive ? "Swipe left on a saved item to archive it." : "Open the menu to add an item or restore the examples.")
                let background = state.makeContentView()
                background.isUserInteractionEnabled = false
                tableView.backgroundView = background
            } else { tableView.backgroundView = nil }
        }
        onChange?()
        if selecting { onSelectionChange?() }
    }

    private func apply(_ next: [Entry], reload: Bool = true) {
        guard next != items else { refreshUI(reload: reload); return }
        items = next
        if let data = try? JSONEncoder().encode(items) { storage.set(data, forKey: defaultsKey) }
        refreshUI(reload: reload)
    }

    func clear() { apply(items.filter { $0.isArchived != showingArchive }) }
    func addItem(named name: String) {
        favoritesOnly = false
        showingArchive = false
        scope.selectedSegmentIndex = 0
        apply(items + [Entry(name: name, symbol: "bookmark", note: "Added to your playground library.")])
    }
    private func replacingScope(with entries: [Entry]) -> [Entry] {
        var result = items
        let positions = items.indices.filter { items[$0].isArchived == showingArchive }
        for (index, entry) in zip(positions, entries) { result[index] = entry }
        return result
    }
    func sortItems() {
        let sorted = scopedItems.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        apply(replacingScope(with: sorted))
    }
    func toggleFilter() { favoritesOnly.toggle(); refreshUI() }
    func toggleFavorite(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        var next = items
        next[i].favorite.toggle()
        apply(next)
    }
    func toggleArchive(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        var next = items
        next[i].archived = !items[i].isArchived
        apply(next)
    }
    func restoreExamples() {
        favoritesOnly = false
        showingArchive = false
        scope.selectedSegmentIndex = 0
        var next = items
        for example in Entry.examples() where !next.contains(where: { $0.name == example.name }) { next.append(example) }
        apply(next)
    }
    func deleteSelection() {
        let ids = selectedIDs
        guard !ids.isEmpty else { return }
        setSelecting(false)
        apply(items.filter { !ids.contains($0.id) })
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { visible.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        visible.isEmpty ? nil : (favoritesOnly ? "Favorites" : (showingArchive ? "Archived items" : "Saved items"))
    }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        visible.isEmpty ? nil : "Edit to delete or reorder. Select to share or delete several items."
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
        if selecting {
            selectedIDs.insert(visible[indexPath.row].id)
            onSelectionChange?()
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        openItem?(visible[indexPath.row].id)
    }
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard selecting else { return }
        selectedIDs.remove(visible[indexPath.row].id)
        onSelectionChange?()
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        remove(visible[indexPath.row].id)
    }
    private func remove(_ id: UUID) {
        guard let row = visible.firstIndex(where: { $0.id == id }) else { return }
        apply(items.filter { $0.id != id }, reload: false)
        tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { !favoritesOnly && !selecting }
    override func tableView(_ tableView: UITableView, moveRowAt source: IndexPath, to destination: IndexPath) {
        var ordered = scopedItems
        let moved = ordered.remove(at: source.row)
        ordered.insert(moved, at: destination.row)
        apply(replacingScope(with: ordered), reload: false)
    }
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt path: IndexPath) -> UISwipeActionsConfiguration? {
        guard !selecting else { return nil }
        let entry = visible[path.row]
        let action = UIContextualAction(style: .normal, title: entry.favorite ? "Unfavorite" : "Favorite") { [weak self] _, _, done in
            self?.toggleFavorite(entry.id)
            done(true)
        }
        action.image = UIImage(systemName: entry.favorite ? "star.slash" : "star")
        action.backgroundColor = .systemOrange
        let config = UISwipeActionsConfiguration(actions: [action])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt path: IndexPath) -> UISwipeActionsConfiguration? {
        guard !selecting else { return nil }
        let entry = visible[path.row]
        let archive = UIContextualAction(style: .normal, title: entry.isArchived ? "Restore" : "Archive") { [weak self] _, _, done in
            self?.toggleArchive(entry.id)
            done(true)
        }
        archive.image = UIImage(systemName: entry.isArchived ? "tray.and.arrow.up" : "archivebox")
        archive.backgroundColor = .systemIndigo
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.remove(entry.id)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        let config = UISwipeActionsConfiguration(actions: isEditing ? [delete] : [archive, delete])
        config.performsFirstActionWithFullSwipe = !isEditing
        return config
    }
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt path: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        guard !selecting else { return nil }
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
