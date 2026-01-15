import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Enhanced Widget Views

struct EnhancedSmallWidgetView: View {
    let entry: TodoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("Tasks")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            if entry.displayItems.isEmpty {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("All done!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.displayItems.prefix(3)) { item in
                        HStack(spacing: 8) {
                            Button(intent: ToggleTodoIntent(id: item.id.uuidString)) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.body)
                                    .foregroundStyle(item.isCompleted ? .green : .blue)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .strikethrough(item.isCompleted)
                                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                                if let time = item.startTime {
                                    Text(time)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                Spacer()

                if entry.pendingCount > 3 {
                    Text("+\(entry.pendingCount - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct EnhancedMediumWidgetView: View {
    let entry: TodoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("Today's Tasks")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()

                VStack(spacing: 2) {
                    Text("\(entry.pendingCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Text("pending")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            if entry.displayItems.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("All tasks completed!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(entry.displayItems.prefix(6)) { item in
                        taskCard(item)
                    }
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private func taskCard(_ item: TodoItem) -> some View {
        HStack(spacing: 6) {
            Button(intent: ToggleTodoIntent(id: item.id.uuidString)) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(item.isCompleted ? .green : .blue)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.caption2)
                    .lineLimit(1)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                if let time = item.startTime {
                    Text(time)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if item.priority != .none {
                Circle()
                    .fill(priorityColor(item.priority))
                    .frame(width: 4, height: 4)
            }
        }
        .padding(8)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colorForTaskColor(item.color), lineWidth: 2)
                .opacity(0.3)
        )
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        case .none: return .gray
        }
    }

    private func colorForTaskColor(_ taskColor: TaskColor) -> Color {
        switch taskColor {
        case .grey: return .gray
        case .rose: return .pink
        case .purple: return .purple
        case .amber: return .orange
        case .sky: return .blue
        case .emerald: return .green
        }
    }
}

struct EnhancedLargeWidgetView: View {
    let entry: TodoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Tasks")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(dateString())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("\(entry.pendingCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Text("pending")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }

            Divider()

            if entry.displayItems.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    Text("All tasks completed!")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("Great job!")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.displayItems) { item in
                        taskRow(item)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private func taskRow(_ item: TodoItem) -> some View {
        HStack(spacing: 12) {
            Button(intent: ToggleTodoIntent(id: item.id.uuidString)) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isCompleted ? .green : .blue)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .lineLimit(2)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let time = item.startTime {
                        Label(time, systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if item.priority != .none {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(priorityColor(item.priority))
                                .frame(width: 4, height: 4)
                            Text(item.priority.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(priorityColor(item.priority))
                        }
                    }

                    if !item.subtasks.isEmpty {
                        Label("\(item.subtasks.count)", systemImage: "list.bullet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Rectangle()
                .fill(colorForTaskColor(item.color))
                .frame(width: 3)
                .cornerRadius(1.5)
        }
        .padding(10)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(10)
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        case .none: return .gray
        }
    }

    private func colorForTaskColor(_ taskColor: TaskColor) -> Color {
        switch taskColor {
        case .grey: return .gray
        case .rose: return .pink
        case .purple: return .purple
        case .amber: return .orange
        case .sky: return .blue
        case .emerald: return .green
        }
    }
}

// MARK: - Enhanced Accessory Widgets

struct EnhancedAccessoryCircularView: View {
    let entry: TodoEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                Text("\(entry.pendingCount)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
}

struct EnhancedAccessoryRectangularView: View {
    let entry: TodoEntry

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)

                if entry.displayItems.isEmpty {
                    Text("All done!")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.displayItems.prefix(2)) { item in
                        HStack(spacing: 4) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption2)
                            Text(item.title)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            Text("\(entry.pendingCount)")
                .font(.title)
                .fontWeight(.bold)
        }
    }
}

struct EnhancedAccessoryInlineView: View {
    let entry: TodoEntry

    var body: some View {
        if entry.pendingCount == 0 {
            Text("All tasks completed!")
        } else if entry.pendingCount == 1 {
            Text("1 task remaining")
        } else {
            Text("\(entry.pendingCount) tasks remaining")
        }
    }
}
