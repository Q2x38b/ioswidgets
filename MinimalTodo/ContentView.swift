import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TodoStore
    @State private var showingAddSheet = false
    @State private var selectedFilter: TodoFilter = .all

    enum TodoFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Done"
    }

    var filteredItems: [TodoItem] {
        switch selectedFilter {
        case .all:
            return store.items
        case .pending:
            return store.pendingItems
        case .completed:
            return store.completedItems
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if store.items.isEmpty {
                    emptyState
                } else {
                    todoList
                }
            }
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }

                if !store.completedItems.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button(role: .destructive) {
                                withAnimation {
                                    store.deleteCompleted()
                                }
                            } label: {
                                Label("Clear Completed", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTodoView()
                    .environmentObject(store)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            Text("No todos yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("Tap + to add your first todo")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }

    private var todoList: some View {
        List {
            if !store.items.isEmpty {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TodoFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            ForEach(filteredItems) { item in
                TodoRowView(item: item) {
                    withAnimation(.snappy(duration: 0.2)) {
                        store.toggle(item)
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.plain)
        .animation(.default, value: filteredItems)
    }

    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { filteredItems[$0] }
        withAnimation {
            for item in itemsToDelete {
                store.delete(item)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore.shared)
}
