import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

enum Demo: Int, CaseIterable, Identifiable {
    case inputs, pickers, buttons, indicators, layout, presentations, search, files, scrollBar
    var id: Self { self }
    var title: String {
        switch self {
        case .inputs: return "Text & Values"
        case .pickers: return "Pickers"
        case .buttons: return "Buttons & Menus"
        case .indicators: return "Progress & Feedback"
        case .layout: return "Collections"
        case .presentations: return "Dialogs & Sheets"
        case .search: return "Search"
        case .files: return "Photos & Files"
        case .scrollBar: return "Scrolling Toolbar"
        }
    }
    var symbol: String {
        switch self {
        case .inputs: return "slider.horizontal.3"
        case .pickers: return "calendar"
        case .buttons: return "button.horizontal"
        case .indicators: return "gauge.with.dots.needle.67percent"
        case .layout: return "rectangle.grid.2x2"
        case .presentations: return "rectangle.portrait.on.rectangle.portrait"
        case .search: return "magnifyingglass"
        case .files: return "photo.on.rectangle"
        case .scrollBar: return "arrow.up.and.down"
        }
    }
}

final class CatalogController: UITableViewController {
    var openPage: ((Demo) -> Void)?
    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("Use init()") }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Demo.allCases.count }
    override func tableView(_ tableView: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell {
        let demo = Demo.allCases[path.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "demo") ?? UITableViewCell(style: .default, reuseIdentifier: "demo")
        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: demo.symbol)
        content.text = demo.title
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt path: IndexPath) {
        tableView.deselectRow(at: path, animated: true)
        openPage?(Demo.allCases[path.row])
    }
}

struct CatalogPage: View {
    let demo: Demo
    @State private var text = ""
    @State private var password = ""
    @State private var notes = ""
    @State private var enabled = true
    @State private var level = 0.45
    @State private var count = 2
    @State private var choice = "Walk"
    @State private var date = Date()
    @State private var tint: Color = .blue
    @State private var expanded = false
    @State private var index = 0
    private let tags = ["Notes", "Maps", "Routes"]
    @State private var selectedTag: String?
    @State private var alert = false
    @State private var dialog = false
    @State private var sheet = false
    @State private var popover = false
    @State private var cover = false
    @State private var fontPicker = false
    @State private var fontName = "System"
    @State private var message = "Draft"
    @State private var pulse = 0
    private let modes = ["Walk", "Cycle", "Drive"]

    @ViewBuilder var body: some View {
        Form {
            switch demo {
            case .inputs: inputs
            case .pickers: pickers
            case .buttons: buttons
            case .indicators: indicators
            case .layout: collections
            case .presentations: presentations
            case .search, .scrollBar: EmptyView()
            case .files: SystemPickers()
            }
        }.scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder private var inputs: some View {
        Section("Text entry") {
            TextField("Name", text: $text).textContentType(.name)
            SecureField("Passphrase", text: $password).textContentType(.newPassword)
            LabeledContent("Notes") { Text("\(notes.count) characters") }
            TextEditor(text: $notes).frame(minHeight: 75).accessibilityLabel("Notes")
        }
        Section("Values") {
            Toggle("Enable level", isOn: $enabled)
            LabeledContent("Level", value: level.formatted(.percent.precision(.fractionLength(0))))
            NativeSlider(value: $level, enabled: enabled).frame(height: 44)
            Stepper("Quantity · \(count)", value: $count, in: 0...20)
        }
    }

    @ViewBuilder private var pickers: some View {
        Section("Selection") {
            Picker("Travel mode", selection: $choice) {
                ForEach(modes, id: \.self) { Text($0) }
            }.pickerStyle(.segmented)
            Picker("Menu", selection: $choice) { ForEach(modes, id: \.self) { Text($0) } }.pickerStyle(.menu)
            Picker("Wheel", selection: $choice) { ForEach(modes, id: \.self) { Text($0) } }
                .pickerStyle(.wheel).frame(height: 110).clipped()
        }
        Section("Date & time") {
            DatePicker("Departure", selection: $date)
            DatePicker("Calendar", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
        }
        Section("Appearance") {
            ColorPicker("Accent", selection: $tint)
            Button { fontPicker = true } label: { LabeledContent("Font", value: fontName) }
                .sheet(isPresented: $fontPicker) { FontPicker(name: $fontName, isPresented: $fontPicker) }
            Text("Sample text").font(.custom(fontName == "System" ? UIFont.systemFont(ofSize: 20).fontName : fontName, size: 20)).foregroundStyle(tint)
        }
    }

    @ViewBuilder private var buttons: some View {
        Section("Actions") {
            LabeledContent("Count", value: "\(count)")
            Button("Add One", systemImage: "plus") { count += 1 }.buttonStyle(.borderedProminent)
            Button("Subtract One", systemImage: "minus") { count -= 1 }.buttonStyle(.bordered).disabled(count == 0)
            Button("Clear", role: .destructive) { count = 0 }.disabled(count == 0)
            ControlGroup {
                Button { count = max(0, count - 1) } label: { Label("Subtract", systemImage: "minus") }
                Button { count += 1 } label: { Label("Add", systemImage: "plus") }
            }
        }
        Section("Menus") {
            Menu {
                Picker("Mode", selection: $choice) { ForEach(modes, id: \.self) { Text($0) } }
            } label: { LabeledContent("Travel mode", value: choice) }
            Text("Touch and hold to select a mode")
                .contextMenu { ForEach(modes, id: \.self) { mode in Button(mode) { choice = mode } } }
        }
    }

    @ViewBuilder private var indicators: some View {
        Section("Progress") {
            ProgressView(value: level) { Text("Completion") }
            Slider(value: $level).accessibilityLabel("Completion")
            Toggle("Show activity", isOn: $enabled)
            if enabled { HStack { ProgressView(); Text("Working").foregroundStyle(.secondary) } }
        }
        Section("Gauge") {
            Gauge(value: level) { Label("Level", systemImage: "dial.medium") }
            Gauge(value: level) { Text("Level") } currentValueLabel: { Text("\(Int(level * 100))") }
                .gaugeStyle(.accessoryCircular)
        }
        Section("Feedback") {
            Button("Play selection feedback") { pulse += 1 }
                .sensoryFeedback(.selection, trigger: pulse)
            Text("Tap on an iPhone to feel the selection change.").font(.footnote).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var collections: some View {
        Section("Disclosure") {
            DisclosureGroup("Saved places", isExpanded: $expanded) {
                ForEach(tags, id: \.self) { Text($0) }
            }
        }
        Section("Paging") {
            TabView(selection: $index) {
                ForEach(Array(tags.enumerated()), id: \.offset) { offset, tag in
                    VStack(spacing: 10) {
                        Image(systemName: ["note.text", "map", "point.topleft.down.to.point.bottomright.curvepath"][offset])
                            .font(.largeTitle)
                        Text(tag).font(.headline)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                     .background(Color.blue.opacity(0.09), in: RoundedRectangle(cornerRadius: 18)).tag(offset)
                }
            }.tabViewStyle(.page(indexDisplayMode: .always))
             .indexViewStyle(.page(backgroundDisplayMode: .always)).frame(height: 160)
        }
        Section("Grid") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                ForEach(tags, id: \.self) { tag in
                    Button { selectedTag = tag } label: { Label(tag, systemImage: selectedTag == tag ? "checkmark.circle.fill" : "circle") }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    @ViewBuilder private var presentations: some View {
        Section("Dialogs") {
            LabeledContent("Document", value: message)
            Button("Rename…") { text = message; alert = true }
                .alert("Rename document", isPresented: $alert) {
                    TextField("Name", text: $text)
                    Button("Cancel", role: .cancel) {}
                    Button("Save") { let name = text.trimmingCharacters(in: .whitespacesAndNewlines); if !name.isEmpty { message = name } }
                }
            Button("Document actions…") { dialog = true }
                .confirmationDialog("Document actions", isPresented: $dialog, titleVisibility: .visible) {
                    Button("Duplicate") { message += " copy" }
                    Button("Reset Name", role: .destructive) { message = "Draft" }
                    Button("Cancel", role: .cancel) {}
                }
        }
        Section("Presentations") {
            Button("Resizable sheet") { sheet = true }
                .sheet(isPresented: $sheet) {
                    SheetDemo().presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
                }
            Button("Popover") { popover = true }
                .popover(isPresented: $popover) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Travel mode").font(.headline)
                        ForEach(modes, id: \.self) { mode in
                            Button(mode) { choice = mode; popover = false }
                        }
                    }.padding().presentationCompactAdaptation(.popover)
                }
            LabeledContent("Travel mode", value: choice)
            Button("Full-screen cover") { cover = true }.fullScreenCover(isPresented: $cover) { SheetDemo() }
            ShareLink(item: message) { Label("Share document name", systemImage: "square.and.arrow.up") }
        }
    }
}

private struct SheetDemo: View {
    @Environment(\.dismiss) var dismiss
    @State private var selected = "Personal"
    var body: some View {
        NavigationStack {
            List(["Personal", "Work", "Travel"], id: \.self) { label in
                Button { selected = label } label: {
                    HStack { Text(label); Spacer(); if selected == label { Image(systemName: "checkmark") } }
                }
            }.navigationTitle("Collections")
             .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct FontPicker: UIViewControllerRepresentable {
    @Binding var name: String
    @Binding var isPresented: Bool
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIFontPickerViewController {
        let picker = UIFontPickerViewController(configuration: UIFontPickerViewController.Configuration())
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIFontPickerViewController, context: Context) {}
    final class Coordinator: NSObject, UIFontPickerViewControllerDelegate {
        let parent: FontPicker
        init(parent: FontPicker) { self.parent = parent }
        func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
            if let descriptor = viewController.selectedFontDescriptor { parent.name = descriptor.postscriptName }
            parent.isPresented = false
        }
        func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) { parent.isPresented = false }
    }
}


final class SearchController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    private let search = UISearchController(searchResultsController: nil)
    private let names = ["Coastal Drive", "City Walk", "Evening Walk", "Mountain Drive", "Market Walk"]
    private var matches: [String] = []
    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("Use init()") }

    override func viewDidLoad() {
        super.viewDidLoad()
        search.searchResultsUpdater = self
        search.searchBar.delegate = self
        search.searchBar.placeholder = "Places"
        search.searchBar.scopeButtonTitles = ["All", "Walk", "Drive"]
        search.scopeBarActivation = .onSearchActivation
        search.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        updateSearchResults(for: search)
    }

    func updateSearchResults(for searchController: UISearchController) {
        let bar = searchController.searchBar
        let scope = bar.scopeButtonTitles?[bar.selectedScopeButtonIndex] ?? "All"
        let query = bar.text ?? ""
        matches = names.filter {
            (scope == "All" || $0.contains(scope)) && (query.isEmpty || $0.localizedCaseInsensitiveContains(query))
        }
        contentUnavailableConfiguration = matches.isEmpty ? UIContentUnavailableConfiguration.search() : nil
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResults(for: search)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { matches.count }
    override func tableView(_ tableView: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "match") ?? UITableViewCell(style: .default, reuseIdentifier: "match")
        var config = cell.defaultContentConfiguration()
        config.text = matches[path.row]
        config.image = UIImage(systemName: matches[path.row].contains("Walk") ? "figure.walk" : "car")
        cell.contentConfiguration = config
        cell.selectionStyle = .none
        return cell
    }
}

private struct SystemPickers: View {
    @State private var photo: PhotosPickerItem?
    @State private var filePicker = false
    @State private var fileName = "None"
    @State private var photoType = "None"

    var body: some View {
        Section("Photo library") {
            PhotosPicker(selection: $photo, matching: .images) { Label("Choose a photo", systemImage: "photo") }
                .onChange(of: photo) { _, item in
                    photoType = item?.supportedContentTypes.first?.localizedDescription ?? "None"
                }
            LabeledContent("Selected type", value: photoType)
        }
        Section("Files") {
            Button("Choose a document", systemImage: "doc") { filePicker = true }
                .fileImporter(isPresented: $filePicker, allowedContentTypes: [.item]) { result in
                    switch result {
                    case .success(let url): fileName = url.lastPathComponent
                    case .failure(let error): fileName = error.localizedDescription
                    }
                }
            LabeledContent("Selection", value: fileName)
        }
    }
}

private struct NativeSlider: UIViewRepresentable {
    @Binding var value: Double
    let enabled: Bool
    func makeCoordinator() -> Coordinator { Coordinator(value: $value) }
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.accessibilityLabel = "Level"
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return slider
    }
    func updateUIView(_ slider: UISlider, context: Context) {
        slider.isEnabled = enabled
        if !slider.isTracking { slider.value = Float(value) }
    }
    final class Coordinator: NSObject {
        @Binding var value: Double
        init(value: Binding<Double>) { _value = value }
        @objc func changed(_ sender: UISlider) { value = Double(sender.value) }
    }
}

/// Shows the iOS 27 navigation-bar minimization API on a native scroll view.
final class ScrollingBarController: UITableViewController {
    private let places = ["Coast", "Old Town", "Lookout", "Market", "Harbor", "Valley",
                          "Village", "Promenade", "Marina", "Museum", "Lake", "Waterfront"]
    private let times = ["Morning", "Midday", "Afternoon", "Evening"]
    private let behavior = UISegmentedControl(items: ["Down", "Up", "Never"])

    override func viewDidLoad() {
        super.viewDidLoad()
        behavior.selectedSegmentIndex = 2
        behavior.accessibilityLabel = "Minimize when scrolling"
        behavior.addTarget(self, action: #selector(configureBar), for: .valueChanged)
        configureBar()
    }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 0 ? "Scroll to collapse the title. Return to the top to expand it." : nil
    }

    @objc private func configureBar() {
        var policy = UIBarMinimization()
        let choices: [UIBarMinimizationBehavior] = [.onScrollDown, .onScrollUp, .never]
        policy.minimizationBehavior = choices[behavior.selectedSegmentIndex]
        navigationItem.navigationBarMinimization = policy
    }
    override func numberOfSections(in tableView: UITableView) -> Int { times.count + 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : places.count
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Minimize on scroll" : times[section - 1]
    }
    override func tableView(_ tableView: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell {
        if path.section == 0 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            behavior.removeFromSuperview()
            behavior.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(behavior)
            let margins = cell.contentView.layoutMarginsGuide
            NSLayoutConstraint.activate([
                behavior.topAnchor.constraint(equalTo: margins.topAnchor),
                behavior.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                behavior.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                behavior.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            ])
            cell.selectionStyle = .none
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "place") ?? UITableViewCell(style: .default, reuseIdentifier: "place")
        var config = cell.defaultContentConfiguration()
        config.text = places[path.row]
        config.image = UIImage(systemName: "mappin")
        cell.contentConfiguration = config
        cell.selectionStyle = .none
        return cell
    }
}
