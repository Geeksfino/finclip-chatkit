import Foundation
import UIKit
import ConvoUI
import EventKit

@available(iOS 15.0, *)
@MainActor
final class CalendarContextProvider: NSObject, @preconcurrency ConvoUIContextProvider {
    private let eventStore: EKEventStore

    var id: String { "chatkit.calendar" }
    var title: String { "Upcoming Event" }
    var iconName: String { "calendar" }
    var isAvailable: Bool { true }
    var priority: Int { 90 }
    var maximumAttachmentCount: Int { 1 }
    var shouldUseContainerPanel: Bool { true }
    
    override init() {
        self.eventStore = EKEventStore()
        super.init()
    }

    nonisolated func makeContext() async throws -> (any ConvoUIContextItem)? {
        // Fallback - return nil to let the collector view handle it
        return nil
    }

    nonisolated func createCollectorView(onConfirm: @escaping ((any ConvoUIContextItem)?) -> Void) -> UIView? {
        print("[Calendar] createCollectorView called")
        let view = CalendarEventCollectorView(eventStore: eventStore)
        view.onConfirm = onConfirm
        print("[Calendar] createCollectorView returning view")
        return view
    }

    func createDetailView(for item: any ConvoUIContextItem, onDismiss: @escaping () -> Void) -> UIView? {
        guard let calendarItem = item as? CalendarContextItem else { return nil }
        let detail = CalendarEventDetailView(item: calendarItem)
        detail.onDismiss = onDismiss
        return detail
    }

    func localizedDescription(for item: any ConvoUIContextItem) -> String {
        guard let calendarItem = item as? CalendarContextItem else {
            return item.displayName
        }
        return calendarItem.summaryText()
    }

    private func makeFallbackEvent() -> EKEvent {
        let fallback = EKEvent(eventStore: eventStore)
        fallback.title = "Sample Meeting"
        fallback.location = "Virtual"
        let start = Date().addingTimeInterval(60 * 60) // 1 hour from now
        fallback.startDate = start
        fallback.endDate = start.addingTimeInterval(45 * 60)
        fallback.notes = "No calendar events found. This sample illustrates the context attachment preview."
        return fallback
    }
}

@available(iOS 15.0, *)
struct CalendarContextItem: ConvoUIContextItem {
    struct Payload: Codable {
        let identifier: String
        let title: String
        let location: String?
        let notes: String?
        let startDate: TimeInterval
        let endDate: TimeInterval
        let isAllDay: Bool
        let isPlaceholder: Bool
        let formattedDateRange: String
    }

    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    let id = UUID()
    let providerId = "chatkit.calendar"
    let type = "calendar_event"

    var displayName: String { event.title }

    let event: EKEvent
    let isPlaceholder: Bool

    init(event: EKEvent, isPlaceholder: Bool = false) {
        self.event = event
        self.isPlaceholder = isPlaceholder
    }

    var codablePayload: Encodable? {
        Payload(
            identifier: event.eventIdentifier ?? UUID().uuidString,
            title: event.title ?? "Untitled Event",
            location: event.location,
            notes: event.notes,
            startDate: event.startDate.timeIntervalSince1970,
            endDate: event.endDate.timeIntervalSince1970,
            isAllDay: event.isAllDay,
            isPlaceholder: isPlaceholder,
            formattedDateRange: summaryText()
        )
    }

    var encodingRepresentation: ConvoUIEncodingType { .json }

    var encodingMetadata: [String: String]? {
        var metadata: [String: String] = [
            "localizedDescription": summaryText(),
            "allDay": event.isAllDay ? "true" : "false",
            "startDate": ISO8601DateFormatter().string(from: event.startDate),
            "endDate": ISO8601DateFormatter().string(from: event.endDate)
        ]

        if let location = event.location, !location.isEmpty {
            metadata["location"] = location
        }
        if isPlaceholder {
            metadata["isPlaceholder"] = "true"
        }

        return metadata.filter { !$0.value.isEmpty }
    }

    var descriptionTemplates: [ContextDescriptionTemplate] {
        [
            ContextDescriptionTemplate(
                locale: "en",
                template: "Calendar event '{title}' scheduled for {formattedDateRange}."
            )
        ]
    }

    func encodeForTransport() throws -> Data {
        guard let payload = codablePayload as? Payload else { return Data() }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(payload)
    }

    func createPreviewView(onRemove: @escaping () -> Void) -> UIView? {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 260, height: 60))
        container.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        container.layer.cornerRadius = 10

        let icon = UILabel(frame: CGRect(x: 12, y: 20, width: 24, height: 24))
        icon.text = "🗓"
        icon.font = UIFont.systemFont(ofSize: 20)
        container.addSubview(icon)

        let titleLabel = UILabel(frame: CGRect(x: 48, y: 8, width: 180, height: 22))
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.text = event.title ?? "(No Title)"
        titleLabel.numberOfLines = 1
        container.addSubview(titleLabel)

        let detailLabel = UILabel(frame: CGRect(x: 48, y: 30, width: 180, height: 22))
        detailLabel.font = UIFont.systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabel
        detailLabel.text = summaryText()
        detailLabel.numberOfLines = 2
        container.addSubview(detailLabel)

        let remove = UIButton(type: .system)
        remove.frame = CGRect(x: 226, y: 18, width: 28, height: 28)
        remove.setTitle("✕", for: .normal)
        remove.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        remove.addAction(UIAction { _ in onRemove() }, for: .touchUpInside)
        container.addSubview(remove)

        return container
    }

    func summaryText() -> String {
        let start = CalendarContextItem.displayFormatter.string(from: event.startDate)
        let range: String
        if event.isAllDay {
            range = "All day • \(start)"
        } else {
            let end = CalendarContextItem.displayFormatter.string(from: event.endDate)
            range = start == end ? start : "\(start) → \(end)"
        }

        return isPlaceholder ? "\(range) (Sample)" : range
    }
}

@available(iOS 15.0, *)
final class CalendarEventCollectorView: UIView, UITableViewDataSource, UITableViewDelegate {
    var onConfirm: (((any ConvoUIContextItem)?) -> Void)?
    
    private var eventStore: EKEventStore?
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let confirmButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var events: [EKEvent] = []
    private var selectedIndex: IndexPath?
    private var hasStartedLoading = false

    init(eventStore: EKEventStore) {
        print("[Calendar] CalendarEventCollectorView init start")
        // Don't capture eventStore in init - will create asynchronously
        super.init(frame: .zero)
        print("[Calendar] super.init done, calling setupUI")
        setupUI()
        print("[Calendar] setupUI done, storing eventStore")
        // Store for later use
        self.eventStore = eventStore
        print("[Calendar] CalendarEventCollectorView init complete")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        // Provide a minimum size hint
        return CGSize(width: 320, height: 400)
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Start loading events using RunLoop.main to avoid blocking
        if window != nil && !hasStartedLoading {
            hasStartedLoading = true
            print("[Calendar] didMoveToWindow - scheduling via CFRunLoop")
            
            // Use CFRunLoop perform to schedule work that will execute
            // when the runloop cycles (after current call stack completes)
            CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue) { [weak self] in
                print("[Calendar] CFRunLoop block executing")
                // Give animation time to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    print("[Calendar] Starting load after delay")
                    self?.startLoadingEvents()
                }
            }
            CFRunLoopWakeUp(CFRunLoopGetMain())
        }
    }
    
    private func setupUI() {
        print("[Calendar] setupUI: setting background color")
        backgroundColor = .systemBackground
        
        print("[Calendar] setupUI: setting translates to false")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        print("[Calendar] setupUI: adding subviews")
        addSubview(tableView)
        addSubview(confirmButton)
        addSubview(loadingIndicator)
        
        print("[Calendar] setupUI: setting dataSource and delegate")
        tableView.dataSource = self
        tableView.delegate = self
        
        // Show loading initially
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        
        confirmButton.setTitle("Use This Event", for: .normal)
        confirmButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        confirmButton.isEnabled = false
        confirmButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if let idx = self.selectedIndex {
                let item = CalendarContextItem(event: self.events[idx.row])
                self.onConfirm?(item)
            } else {
                self.onConfirm?(nil)
            }
        }, for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -12),
            
            confirmButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func startLoadingEvents() {
        print("[Calendar] startLoadingEvents called on thread: \(Thread.isMainThread ? "MAIN" : "BACKGROUND")")
        
        guard let eventStore = self.eventStore else {
            print("[Calendar] No event store available")
            return
        }
        
        print("[Calendar] Requesting calendar access...")
        
        // Use modern async API on iOS 17+ to avoid blocking
        if #available(iOS 17.0, *) {
            Task { @MainActor in
                do {
                    print("[Calendar] Using iOS 17+ async requestFullAccessToEvents")
                    let granted = try await eventStore.requestFullAccessToEvents()
                    print("[Calendar] Access granted: \(granted)")
                    
                    self.loadingIndicator.stopAnimating()
                    
                    guard granted else {
                        print("[Calendar] Access denied")
                        self.showNoPermissionState()
                        return
                    }
                    
                    print("[Calendar] Fetching events...")
                    let start = Date()
                    let end = Calendar.current.date(byAdding: .day, value: 30, to: start) ?? start
                    let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
                    self.events = eventStore.events(matching: predicate)
                        .filter { $0.startDate >= start }
                        .sorted(by: { $0.startDate < $1.startDate })
                    
                    print("[Calendar] Found \(self.events.count) events, reloading table")
                    self.tableView.reloadData()
                    
                    if self.events.isEmpty {
                        self.showEmptyState()
                    }
                } catch {
                    print("[Calendar] Error requesting access: \(error)")
                    await MainActor.run {
                        self.loadingIndicator.stopAnimating()
                        self.showNoPermissionState()
                    }
                }
            }
        } else {
            // Fallback for iOS 16 and below - use old callback API with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("[Calendar] Using legacy requestAccess API")
                eventStore.requestAccess(to: .event) { [weak self] granted, error in
                    print("[Calendar] Legacy access request completed: granted=\(granted)")
                    guard let self else { return }
                    
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                        
                        guard granted else {
                            print("[Calendar] Access denied")
                            self.showNoPermissionState()
                            return
                        }
                        
                        print("[Calendar] Fetching events...")
                        let start = Date()
                        let end = Calendar.current.date(byAdding: .day, value: 30, to: start) ?? start
                        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
                        self.events = eventStore.events(matching: predicate)
                            .filter { $0.startDate >= start }
                            .sorted(by: { $0.startDate < $1.startDate })
                        
                        print("[Calendar] Found \(self.events.count) events")
                        self.tableView.reloadData()
                        
                        if self.events.isEmpty {
                            self.showEmptyState()
                        }
                    }
                }
            }
        }
    }
    
    private func showNoPermissionState() {
        let label = UILabel()
        label.text = "Calendar access not granted\nPlease enable in Settings"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        tableView.backgroundView = label
    }
    
    private func showEmptyState() {
        let container = UIView()
        
        let label = UILabel()
        label.text = "📅\n\nNo upcoming events\nin the next 30 days"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        tableView.backgroundView = container
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "CalendarEventCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: id) ?? UITableViewCell(style: .subtitle, reuseIdentifier: id)
        let ev = events[indexPath.row]
        cell.textLabel?.text = ev.title ?? "(No Title)"
        let start = CalendarContextItem.displayFormatter.string(from: ev.startDate)
        let end = CalendarContextItem.displayFormatter.string(from: ev.endDate)
        let range = ev.isAllDay ? "All day • \(start)" : (start == end ? start : "\(start) → \(end)")
        cell.detailTextLabel?.text = range
        cell.accessoryType = (indexPath == selectedIndex) ? .checkmark : .none
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let prev = selectedIndex, let c = tableView.cellForRow(at: prev) {
            c.accessoryType = .none
        }
        selectedIndex = indexPath
        if let c = tableView.cellForRow(at: indexPath) {
            c.accessoryType = .checkmark
        }
        confirmButton.isEnabled = true
    }
}

@available(iOS 15.0, *)
final class CalendarEventDetailView: UIView {
    var onDismiss: (() -> Void)?

    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let locationLabel = UILabel()
    private let notesLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let item: CalendarContextItem

    init(item: CalendarContextItem) {
        self.item = item
        super.init(frame: .zero)
        setupUI()
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground

        [titleLabel, timeLabel, locationLabel, notesLabel, closeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 2

        timeLabel.font = UIFont.preferredFont(forTextStyle: .body)
        timeLabel.numberOfLines = 2

        locationLabel.font = UIFont.preferredFont(forTextStyle: .body)
        locationLabel.numberOfLines = 0
        locationLabel.textColor = .secondaryLabel

        notesLabel.font = UIFont.preferredFont(forTextStyle: .body)
        notesLabel.numberOfLines = 0
        notesLabel.textColor = .secondaryLabel

        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        closeButton.addTarget(self, action: #selector(handleCloseTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            locationLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 12),
            locationLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            notesLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 12),
            notesLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            notesLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 24),
            closeButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    private func configure() {
        titleLabel.text = item.event.title ?? "(No Title)"
        timeLabel.text = item.summaryText()

        if let location = item.event.location, !location.isEmpty {
            locationLabel.isHidden = false
            locationLabel.text = "Location: \(location)"
        } else {
            locationLabel.isHidden = true
        }

        if let notes = item.event.notes, !notes.isEmpty {
            notesLabel.isHidden = false
            notesLabel.text = "Notes:\n\(notes)"
        } else {
            notesLabel.isHidden = true
        }
    }

    @objc private func handleCloseTapped() {
        onDismiss?()
    }
}
