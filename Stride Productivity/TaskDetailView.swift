import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TodoStore

    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = true
    @State private var startTime = ""
    @State private var endTime = ""
    @State private var selectedColor: TaskColor = .grey
    @State private var selectedPriority: TaskPriority = .none
    @State private var status = ""
    @State private var customTags: [String] = []
    @State private var newTag = ""
    @State private var subtasks: [String] = []
    @State private var newSubtask = ""
    @State private var recurring = ""
    @State private var reminder = ""
    @State private var location = ""
    @State private var showingTimeStart = false
    @State private var showingTimeEnd = false
    @State private var showingLocationSearch = false

    let existingItem: TodoItem?

    init(item: TodoItem? = nil) {
        self.existingItem = item
        if let item = item {
            _title = State(initialValue: item.title)
            _description = State(initialValue: item.description)
            _dueDate = State(initialValue: item.dueDate ?? Date())
            _hasDueDate = State(initialValue: item.dueDate != nil)
            _startTime = State(initialValue: item.startTime ?? "")
            _endTime = State(initialValue: item.endTime ?? "")
            _selectedColor = State(initialValue: item.color)
            _selectedPriority = State(initialValue: item.priority)
            _status = State(initialValue: item.status)
            _customTags = State(initialValue: item.customTags)
            _subtasks = State(initialValue: item.subtasks)
            _recurring = State(initialValue: item.recurring)
            _reminder = State(initialValue: item.reminder ?? "")
            _location = State(initialValue: item.location)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("What needs to be done?", text: $title)
                        .font(.headline)

                    TextField("Add details...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Schedule") {
                    Toggle("Set due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }

                    HStack {
                        Text("Start Time")
                        Spacer()
                        TextField("09:00", text: $startTime)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("End Time")
                        Spacer()
                        TextField("17:00", text: $endTime)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .frame(width: 80)
                    }
                }

                Section("Organization") {
                    Picker("Color", selection: $selectedColor) {
                        ForEach(TaskColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(colorForTaskColor(color))
                                    .frame(width: 16, height: 16)
                                Text(color.displayName)
                            }
                            .tag(color)
                        }
                    }

                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                priorityIcon(for: priority)
                                Text(priority.rawValue.capitalized)
                            }
                            .tag(priority)
                        }
                    }

                    TextField("Status", text: $status)
                }

                Section("Tags") {
                    ForEach(customTags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)

                            Spacer()

                            Button {
                                customTags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    HStack {
                        TextField("Add tag...", text: $newTag)
                            .onSubmit {
                                if !newTag.isEmpty {
                                    customTags.append(newTag)
                                    newTag = ""
                                }
                            }

                        Button("Add") {
                            if !newTag.isEmpty {
                                customTags.append(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                    }
                }

                Section("Subtasks") {
                    ForEach(subtasks, id: \.self) { subtask in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                            Text(subtask)

                            Spacer()

                            Button {
                                subtasks.removeAll { $0 == subtask }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    HStack {
                        TextField("Add subtask...", text: $newSubtask)
                            .onSubmit {
                                if !newSubtask.isEmpty {
                                    subtasks.append(newSubtask)
                                    newSubtask = ""
                                }
                            }

                        Button("Add") {
                            if !newSubtask.isEmpty {
                                subtasks.append(newSubtask)
                                newSubtask = ""
                            }
                        }
                        .disabled(newSubtask.isEmpty)
                    }
                }

                Section("Additional") {
                    Button {
                        showingLocationSearch = true
                    } label: {
                        HStack {
                            Text("Location")
                                .foregroundStyle(.primary)
                            Spacer()
                            if location.isEmpty {
                                Text("Add location")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(location)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    TextField("Reminder", text: $reminder)
                    TextField("Recurring", text: $recurring)
                }
            }
            .navigationTitle(existingItem == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingLocationSearch) {
            LocationSearchView(location: $location)
        }
    }

    private func priorityIcon(for priority: TaskPriority) -> some View {
        Group {
            switch priority {
            case .none:
                Image(systemName: "minus.circle")
                    .foregroundStyle(.gray)
            case .low:
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
            case .medium:
                Image(systemName: "equal.circle.fill")
                    .foregroundStyle(.orange)
            case .high:
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.body)
    }

    private func saveTask() {
        if let existingItem = existingItem {
            store.update(existingItem.id) { item in
                item.title = title
                item.description = description
                item.dueDate = hasDueDate ? dueDate : nil
                item.startTime = startTime.isEmpty ? nil : startTime
                item.endTime = endTime.isEmpty ? nil : endTime
                item.color = selectedColor
                item.priority = selectedPriority
                item.status = status
                item.customTags = customTags
                item.subtasks = subtasks
                item.recurring = recurring
                item.reminder = reminder.isEmpty ? nil : reminder
                item.location = location
            }
        } else {
            let newItem = TodoItem(
                title: title,
                description: description,
                dueDate: hasDueDate ? dueDate : nil,
                startTime: startTime.isEmpty ? nil : startTime,
                endTime: endTime.isEmpty ? nil : endTime,
                color: selectedColor,
                priority: selectedPriority,
                status: status,
                customTags: customTags,
                subtasks: subtasks,
                recurring: recurring,
                reminder: reminder.isEmpty ? nil : reminder,
                location: location
            )
            _ = store.add(newItem)
        }

        dismiss()
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
    TaskDetailView()
        .environmentObject(TodoStore.shared)
}
