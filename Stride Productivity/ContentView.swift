import SwiftUI


enum ViewMode: String, CaseIterable {
    case schedule = "Schedule"
    case calendar = "Calendar"
    case boards = "Boards"
    case settings = "Settings"

    var iconName: String {
        switch self {
        case .schedule: return "list.bullet"
        case .calendar: return "calendar"
        case .boards: return "square.grid.2x2"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: TodoStore
    @State private var selectedView: ViewMode = .schedule
    @State private var showingAddSheet = false
    @State private var selectedDate = Date()
    @State private var showSidebar = true
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout with sidebar
                iPadLayout
            } else {
                // iPhone layout with bottom toolbar
                iPhoneLayout
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            TaskDetailView()
                .environmentObject(store)
        }
    }

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("MinimalTodo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation {
                                    selectedView = mode
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: mode.iconName)
                                        .font(.title3)
                                        .frame(width: 24)
                                    Text(mode.rawValue)
                                        .font(.body)
                                    Spacer()
                                }
                                .foregroundStyle(selectedView == mode ? Color.appAccent : .primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedView == mode ? Color.appAccent.opacity(0.15) : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                        }

                        Divider()
                            .padding(.vertical, 12)

                        Button {
                            showingAddSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .frame(width: 24)
                                Text("New Task")
                                    .font(.body)
                                Spacer()
                            }
                            .foregroundStyle(Color.appAccent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 8)
                }

                Spacer()
            }
            .frame(width: 250)
            .background(Color(.systemGray6).opacity(0.3))

            Divider()

            // Main content
            switch selectedView {
            case .schedule:
                ScheduleView(selectedDate: $selectedDate, showingAddSheet: $showingAddSheet)
            case .calendar:
                CalendarView(store: store, selectedDate: $selectedDate)
            case .boards:
                BoardsView(store: store)
            case .settings:
                SettingsView()
            }
        }
    }

    private var iPhoneLayout: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                switch selectedView {
                case .schedule:
                    ScheduleView(selectedDate: $selectedDate, showingAddSheet: $showingAddSheet)
                case .calendar:
                    CalendarView(store: store, selectedDate: $selectedDate)
                case .boards:
                    BoardsView(store: store)
                case .settings:
                    SettingsView()
                }
            }

            // Floating liquid glass toolbar
            bottomNavigation
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard)
    }

    private var bottomNavigation: some View {
        let toolbarHeight: CGFloat = 60
        let plusButtonSize: CGFloat = 52
        let iconSize: CGFloat = 24
        let cornerRadius: CGFloat = 30

        return HStack(spacing: 0) {
            // Schedule button
            navButton(for: .schedule, iconSize: iconSize)

            // Calendar button
            navButton(for: .calendar, iconSize: iconSize)

            // Centered large + button
            Button {
                showingAddSheet = true
            } label: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appAccent, Color.appAccentDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: plusButtonSize, height: plusButtonSize)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Color.appAccent.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .frame(maxWidth: .infinity)

            // Boards button
            navButton(for: .boards, iconSize: iconSize)

            // Settings button
            navButton(for: .settings, iconSize: iconSize)
        }
        .frame(height: toolbarHeight)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    private func navButton(for mode: ViewMode, iconSize: CGFloat) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedView = mode
            }
        } label: {
            Image(systemName: mode.iconName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(selectedView == mode ? Color.appAccent : Color.secondary.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ScheduleView: View {
    @EnvironmentObject var store: TodoStore
    @Binding var selectedDate: Date
    @Binding var showingAddSheet: Bool
    @State private var showingEditSheet = false
    @State private var selectedItem: TodoItem?

    var todaysTasks: [TodoItem] {
        store.sortedItems(for: selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                datePickerHeader

                if store.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if todaysTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            store.reload()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        if !store.completedItems.isEmpty {
                            Button(role: .destructive) {
                                withAnimation {
                                    store.deleteCompleted()
                                }
                            } label: {
                                Label("Clear Completed", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            TaskDetailView(item: item)
                .environmentObject(store)
        }
    }

    private var datePickerHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Show yesterday, today, and next 7 days
                ForEach(-1...7, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    datePill(for: date)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
    }

    private func datePill(for date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)
        let tasksForDay = store.sortedItems(for: date)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 6) {
                Text(dayName(for: date))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .textCase(.uppercase)

                Text(dayNumber(for: date))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? .white : .primary)

                // Task indicator dots
                if !tasksForDay.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(tasksForDay.prefix(3)) { task in
                            Circle()
                                .fill(isSelected ? Color.white.opacity(0.7) : colorForTaskColor(task.color))
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Spacer()
                        .frame(height: 4)
                }
            }
            .frame(width: 70, height: 85)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ?
                          LinearGradient(colors: [Color.appAccent, Color.appAccentDark],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(.systemGray6).opacity(0.5)],
                                       startPoint: .top,
                                       endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isToday && !isSelected ? Color.appAccent : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.appAccent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
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

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            Text("No tasks for this day")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("Tap + to add a new task")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(todaysTasks) { item in
                    TaskRowView(item: item) {
                        withAnimation(.snappy(duration: 0.2)) {
                            store.toggle(item)
                        }
                    }
                    .onTapGesture {
                        selectedItem = item
                    }
                    .contextMenu {
                        Button {
                            selectedItem = item
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            withAnimation {
                                store.delete(item)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
}

struct CalendarView: View {
    @ObservedObject var store: TodoStore
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()
    @State private var selectedItem: TodoItem?
    @State private var draggedItem: TodoItem?
    @State private var showingEditSheet = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            if horizontalSizeClass == .regular {
                // iPad: Large calendar view
                iPadCalendarLayout
            } else {
                // iPhone: Compact view
                iPhoneCalendarLayout
            }
        }
        .sheet(item: $selectedItem) { item in
            TaskDetailView(item: item)
                .environmentObject(store)
        }
    }

    private var iPadCalendarLayout: some View {
        HStack(spacing: 0) {
            // Large calendar on the left
            ScrollView {
                VStack(spacing: 30) {
                    monthHeader
                    calendarGrid
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 30)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Tasks list on the right
            VStack(alignment: .leading, spacing: 0) {
                Text(dateString(for: selectedDate))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()

                Divider()

                tasksListOnly
            }
            .frame(width: 400)
            .background(Color(.systemGray6).opacity(0.3))
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var iPhoneCalendarLayout: some View {
        ScrollView {
            VStack(spacing: 20) {
                monthHeader
                calendarGrid
                tasksForSelectedDay
            }
            .padding()
            .padding(.bottom, 100)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tasksListOnly: some View {
        ScrollView {
            let tasks = store.sortedItems(for: selectedDate)

            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("No tasks for this day")
                        .font(.subheadline)
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
                .padding()
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appAccent)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(monthYearString(for: currentMonth))
                    .font(.title)
                    .fontWeight(.bold)

                let tasksThisMonth = store.items.filter { item in
                    guard let dueDate = item.dueDate else { return false }
                    return Calendar.current.isDate(dueDate, equalTo: currentMonth, toGranularity: .month)
                }
                Text("\(tasksThisMonth.count) tasks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appAccent)
            }
        }
        .padding(.horizontal)
    }

    private var calendarGrid: some View {
        let days = generateDaysInMonth(for: currentMonth)
        let isIPad = horizontalSizeClass == .regular

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: isIPad ? 12 : 8), count: 7), spacing: isIPad ? 12 : 8) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(isIPad ? .body : .caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, isIPad ? 12 : 8)
            }

            ForEach(days, id: \.self) { date in
                if let date = date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: isIPad ? 100 : 70)
                }
            }
        }
        .padding(isIPad ? 20 : 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }

    private func dayCell(for date: Date) -> some View {
        let tasksForDay = store.sortedItems(for: date)
        let isToday = Calendar.current.isDateInToday(date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isCurrentMonth = Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isIPad = horizontalSizeClass == .regular

        return VStack(alignment: .leading, spacing: 4) {
            // Day number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(isIPad ? .body : .caption)
                .fontWeight(isSelected || isToday ? .bold : .regular)
                .foregroundStyle(
                    isSelected ? Color.white :
                    isToday ? Color.appAccent :
                    isCurrentMonth ? Color.primary : Color.secondary.opacity(0.5)
                )
                .frame(maxWidth: .infinity, alignment: .leading)

            // Tasks in this day (iPad only)
            if isIPad && !tasksForDay.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(tasksForDay.prefix(3)) { task in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isSelected ? Color.white.opacity(0.8) : colorForTaskColor(task.color))
                                .frame(width: 4, height: 4)
                            Text(task.title)
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .foregroundStyle(isSelected ? Color.white.opacity(0.9) : Color.primary.opacity(0.7))
                        }
                        .onDrag {
                            self.draggedItem = task
                            return NSItemProvider(object: task.id.uuidString as NSString)
                        }
                    }
                    if tasksForDay.count > 3 {
                        Text("+\(tasksForDay.count - 3) more")
                            .font(.system(size: 8))
                            .foregroundStyle(isSelected ? Color.white.opacity(0.7) : .secondary)
                    }
                }
            } else if !isIPad && !tasksForDay.isEmpty {
                // iPhone: just show dots
                HStack(spacing: 2) {
                    ForEach(tasksForDay.prefix(3)) { task in
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.8) : colorForTaskColor(task.color))
                            .frame(width: 5, height: 5)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: isIPad ? 100 : 70)
        .padding(isIPad ? 8 : 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ?
                      LinearGradient(colors: [Color.appAccent, Color.appAccentDark],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing) :
                      LinearGradient(colors: [Color(.systemBackground)],
                                   startPoint: .top,
                                   endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isToday && !isSelected ? Color.appAccent :
                    !tasksForDay.isEmpty && !isSelected ? Color(.systemGray4) :
                    Color.clear,
                    lineWidth: isToday && !isSelected ? 2 : 1
                )
        )
        .shadow(color: isSelected ? Color.appAccent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
            }
        }
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers: providers, date: date)
        }
    }

    private var tasksForSelectedDay: some View {
        let tasks = store.sortedItems(for: selectedDate)

        return VStack(alignment: .leading, spacing: 12) {
            Text(dateString(for: selectedDate))
                .font(.title3)
                .fontWeight(.bold)

            if tasks.isEmpty {
                Text("No tasks for this day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
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
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
    }

    private func handleDrop(providers: [NSItemProvider], date: Date) -> Bool {
        guard let draggedItem = draggedItem else { return false }

        store.update(draggedItem.id) { item in
            item.dueDate = date
        }

        self.draggedItem = nil
        return true
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
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

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func generateDaysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: date)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let numDays = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 0..<numDays {
            if let date = calendar.date(byAdding: .day, value: day, to: interval.start) {
                days.append(date)
            }
        }

        return days
    }
}

struct BoardsView: View {
    @ObservedObject var store: TodoStore
    @State private var draggedItem: TodoItem?
    @State private var selectedItem: TodoItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    boardColumn(
                        title: "To Do",
                        status: "",
                        items: store.items.filter { $0.status.isEmpty && !$0.isCompleted },
                        color: Color.appAccent
                    )
                    boardColumn(
                        title: "In Progress",
                        status: "In Progress",
                        items: store.items.filter { $0.status.lowercased().contains("progress") },
                        color: .orange
                    )
                    boardColumn(
                        title: "Completed",
                        status: "Completed",
                        items: store.completedItems,
                        color: .green
                    )
                }
                .padding()
                .padding(.bottom, 100)
            }
            .navigationTitle("Boards")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $selectedItem) { item in
            TaskDetailView(item: item)
                .environmentObject(store)
        }
    }

    private func boardColumn(title: String, status: String, items: [TodoItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(items.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
            }

            ForEach(items) { item in
                TaskRowView(item: item) {
                    withAnimation(.snappy(duration: 0.2)) {
                        store.toggle(item)
                    }
                }
                .onTapGesture {
                    selectedItem = item
                }
                .onDrag {
                    self.draggedItem = item
                    return NSItemProvider(object: item.id.uuidString as NSString)
                }
            }

            if items.isEmpty {
                Text("Drag tasks here")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(.systemGray5).opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 2)
                )
        )
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleBoardDrop(providers: providers, status: status)
        }
    }

    private func handleBoardDrop(providers: [NSItemProvider], status: String) -> Bool {
        guard let draggedItem = draggedItem else { return false }

        store.update(draggedItem.id) { item in
            if status == "Completed" {
                if !item.isCompleted {
                    item.toggle()
                }
                item.status = status
            } else {
                if item.isCompleted {
                    item.toggle()
                }
                item.status = status
            }
        }

        self.draggedItem = nil
        return true
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore.shared)
}
