import SwiftUI

struct DayDetailView: View {
    @ObservedObject var store: TodoStore
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: TodoItem?
    @State private var draggedItem: TodoItem?

    var tasks: [TodoItem] {
        store.sortedItems(for: selectedDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Date header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(monthDayString(for: selectedDate))
                            .font(.title)
                            .fontWeight(.bold)
                        Text(dayOfWeekString(for: selectedDate))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Task count
                    if !tasks.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.appAccent)
                            Text("\(tasks.filter { $0.isCompleted }.count) of \(tasks.count) completed")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // Tasks list
                    if tasks.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 64))
                                .foregroundStyle(.tertiary)
                            Text("No tasks for this day")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(tasks) { task in
                                TaskRowView(item: task) {
                                    withAnimation {
                                        store.toggle(task)
                                    }
                                }
                                .onTapGesture {
                                    selectedItem = task
                                }
                                .onDrag {
                                    self.draggedItem = task
                                    return NSItemProvider(object: task.id.uuidString as NSString)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("Calendar")
                                .font(.body)
                        }
                        .foregroundStyle(Color.appAccent)
                    }
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            TaskDetailView(item: item)
                .environmentObject(store)
        }
    }

    private func monthDayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func dayOfWeekString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
