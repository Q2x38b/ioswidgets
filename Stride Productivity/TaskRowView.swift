import SwiftUI

struct TaskRowView: View {
    let item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Color indicator bar - more prominent like Stride
            Rectangle()
                .fill(colorForTaskColor(item.color))
                .frame(width: 4)

            HStack(spacing: 12) {
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .strokeBorder(item.isCompleted ? Color.appAccent : Color(.systemGray3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if item.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(item.isCompleted ? .secondary : .primary)
                            .strikethrough(item.isCompleted)

                        if item.priority != .none {
                            priorityIndicator(item.priority)
                        }
                    }

                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        if let startTime = item.startTime {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(startTime)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }

                        if !item.status.isEmpty {
                            Text(item.status)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appAccent.opacity(0.2))
                                .cornerRadius(4)
                                .foregroundStyle(Color.appAccent)
                        }

                        if !item.subtasks.isEmpty {
                            let completed = item.subtasks.filter { $0.hasPrefix("✓") }.count
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .font(.caption2)
                                Text("\(completed)/\(item.subtasks.count)")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    if !item.customTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(item.customTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(colorForTaskColor(item.color).opacity(0.15))
                                        .foregroundStyle(colorForTaskColor(item.color))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorForTaskColor(item.color).opacity(0.3), lineWidth: 1)
        )
    }

    // Priority indicator with icons
    private func priorityIndicator(_ priority: TaskPriority) -> some View {
        Group {
            switch priority {
            case .none:
                EmptyView()
            case .low:
                Image(systemName: "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            case .medium:
                Image(systemName: "equal.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            case .high:
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func priorityBadge(_ priority: TaskPriority) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(priorityColor(priority))
                .frame(width: 6, height: 6)
            Text(priority.rawValue.capitalized)
                .font(.caption2)
                .foregroundStyle(priorityColor(priority))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(priorityColor(priority).opacity(0.2))
        .cornerRadius(4)
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return Color.appAccent
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

#Preview {
    VStack(spacing: 12) {
        TaskRowView(
            item: TodoItem(
                title: "Buy groceries",
                description: "Get milk, eggs, and bread from the store",
                startTime: "09:00",
                priority: .high,
                customTags: ["Shopping", "Urgent"]
            ),
            onToggle: {}
        )

        TaskRowView(
            item: TodoItem(
                title: "Finish project",
                isCompleted: true,
                startTime: "14:00",
                color: .emerald,
                priority: .medium,
                status: "Done"
            ),
            onToggle: {}
        )
    }
    .padding()
}
