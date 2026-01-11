import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Provider

struct TodoProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), items: TodoItem.previewList, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> TodoEntry {
        let items = TodoStore.loadItems()
        return TodoEntry(date: Date(), items: items, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<TodoEntry> {
        let items = TodoStore.loadItems()
        let entry = TodoEntry(date: Date(), items: items, configuration: configuration)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description = IntentDescription("Choose what to display")

    @Parameter(title: "Show Completed", default: false)
    var showCompleted: Bool

    @Parameter(title: "Max Items", default: 5)
    var maxItems: Int
}

// MARK: - Timeline Entry

struct TodoEntry: TimelineEntry {
    let date: Date
    let items: [TodoItem]
    let configuration: ConfigurationAppIntent

    var displayItems: [TodoItem] {
        let filtered = configuration.showCompleted ? items : items.filter { !$0.isCompleted }
        return Array(filtered.prefix(configuration.maxItems))
    }

    var pendingCount: Int {
        items.filter { !$0.isCompleted }.count
    }
}

// MARK: - Widget Views

struct TodoWidgetEntryView: View {
    var entry: TodoProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: TodoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.headline)
                Text("Todos")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.primary)

            if entry.displayItems.isEmpty {
                Spacer()
                Text("All done!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.displayItems.prefix(3)) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundStyle(item.isCompleted ? .green : .secondary)
                            Text(item.title)
                                .font(.caption)
                                .lineLimit(1)
                                .strikethrough(item.isCompleted)
                                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            if entry.pendingCount > 0 {
                Text("\(entry.pendingCount) remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: TodoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.headline)
                Text("Todos")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if entry.pendingCount > 0 {
                    Text("\(entry.pendingCount) remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if entry.displayItems.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("All done!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 6) {
                    ForEach(entry.displayItems.prefix(6)) { item in
                        WidgetTodoRow(item: item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: TodoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                Text("Todos")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                if entry.pendingCount > 0 {
                    Text("\(entry.pendingCount) remaining")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            if entry.displayItems.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("All done!")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Tap to add a new todo")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.displayItems) { item in
                        WidgetTodoRow(item: item, showToggle: true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Accessory Views (Lock Screen)

struct AccessoryCircularView: View {
    let entry: TodoEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "checkmark.circle")
                    .font(.caption)
                Text("\(entry.pendingCount)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: TodoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                Text("Todos")
                    .fontWeight(.semibold)
            }
            .font(.caption)

            if entry.displayItems.isEmpty {
                Text("All done!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.displayItems.prefix(2)) { item in
                    Text(item.title)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AccessoryInlineView: View {
    let entry: TodoEntry

    var body: some View {
        if entry.pendingCount == 0 {
            Label("All done!", systemImage: "checkmark.circle")
        } else {
            Label("\(entry.pendingCount) todos remaining", systemImage: "checkmark.circle")
        }
    }
}

// MARK: - Shared Components

struct WidgetTodoRow: View {
    let item: TodoItem
    var showToggle: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if showToggle {
                Button(intent: ToggleTodoIntent(id: item.id.uuidString)) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }

            Text(item.title)
                .font(.caption)
                .lineLimit(1)
                .strikethrough(item.isCompleted)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
        }
    }
}

// MARK: - Widget Definition

struct TodoWidget: Widget {
    let kind: String = "TodoWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: TodoProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Todo List")
        .description("View and manage your todos.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Toggle Intent for Interactive Widget

struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Todo"
    static var description = IntentDescription("Mark a todo as complete or incomplete")

    @Parameter(title: "Todo ID")
    var id: String

    init() {
        self.id = ""
    }

    init(id: String) {
        self.id = id
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: id) else {
            return .result()
        }
        _ = TodoStore.toggleItem(id: uuid)
        return .result()
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    TodoWidget()
} timeline: {
    TodoEntry(date: .now, items: TodoItem.previewList, configuration: ConfigurationAppIntent())
    TodoEntry(date: .now, items: [], configuration: ConfigurationAppIntent())
}

#Preview(as: .systemMedium) {
    TodoWidget()
} timeline: {
    TodoEntry(date: .now, items: TodoItem.previewList, configuration: ConfigurationAppIntent())
}

#Preview(as: .systemLarge) {
    TodoWidget()
} timeline: {
    TodoEntry(date: .now, items: TodoItem.previewList, configuration: ConfigurationAppIntent())
}
