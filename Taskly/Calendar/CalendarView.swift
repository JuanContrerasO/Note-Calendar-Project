import SwiftUI
import SwiftData
import EventKit
 
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @State private var showingAddTask = false
    @State private var selectedDate = Date()
    @State private var calendarManager = CalendarManager()
 
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "161f35"))
                    .cornerRadius(10)
                    .colorScheme(.dark)
 
                if let errorMessage = calendarManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(Color(hex: "E24B4A"))
                        .padding(.horizontal)
                }
 
                List {
                    if !calendarManager.events.isEmpty {
                        Section("Calendar Events") {
                            ForEach(calendarManager.events, id: \.eventIdentifier) { event in
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .foregroundColor(Color(hex: "7C6FF7"))
                                    VStack(alignment: .leading) {
                                        Text(event.title)
                                            .font(.body)
                                            .foregroundColor(Color(hex: "e8edf5"))
                                        if let startDate = event.startDate {
                                            Text(startDate, style: .time)
                                                .font(.caption)
                                                .foregroundColor(Color(hex: "5a6a8a"))
                                        }
                                    }
                                }
                            }
                        }
                    }
 
                    Section("Tasks") {
                        ForEach(filteredTasks) { task in
                            NavigationLink(destination: EditTaskView(task: task)) {
                                HStack {
                                    Button(action: { toggleTask(task) }) {
                                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.isCompleted ? Color(hex: "2DD4BF") : Color(hex: "3a4a6a"))
                                    }
                                    .buttonStyle(.plain)
 
                                    VStack(alignment: .leading) {
                                        Text(task.title)
                                            .strikethrough(task.isCompleted)
                                            .foregroundColor(Color(hex: task.isCompleted ? "4a5a7a" : "e8edf5"))
                                        Text(task.date, style: .time)
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "5a6a8a"))
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteTask)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(hex: "0F1629"))
                .listStyle(InsetGroupedListStyle())
            }
            .background(Color(hex: "0F1629"))
            .navigationTitle("Calendar")
            .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddTask, onDismiss: {
                calendarManager.fetchEvents(for: selectedDate)
            }) {
                AddTaskView(selectedDate: selectedDate, calendarManager: calendarManager)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                Task {
                    await calendarManager.requestAccess()
                    calendarManager.fetchEvents(for: selectedDate)
                    NotificationManager.shared.listPendingNotifications() // debug
                }
            }
            .onChange(of: selectedDate) { _, newDate in
                calendarManager.fetchEvents(for: newDate)
            }
        }
    }

    var filteredTasks: [TaskItem] {
        tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date < $1.date }
    }
 
    func toggleTask(_ task: TaskItem) {
        task.isCompleted.toggle()
        if task.isCompleted {
            NotificationManager.shared.cancelNotification(for: task)
        }
    }
 
    func deleteTask(at offsets: IndexSet) {
        let filtered = filteredTasks
        for index in offsets {
            let task = filtered[index]
            NotificationManager.shared.cancelNotification(for: task)
            modelContext.delete(task)
        }
    }
}
 
struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    let selectedDate: Date
    var calendarManager: CalendarManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var taskDate: Date
    @State private var addToCalendar = true
    @State private var setReminder = false
    @State private var reminderDate = Date()
 
    init(selectedDate: Date, calendarManager: CalendarManager) {
        self.selectedDate = selectedDate
        self.calendarManager = calendarManager
        self._taskDate = State(initialValue: selectedDate)
    }
 
    var body: some View {
        NavigationStack {
            Form {
                TextField("Task Title", text: $title)
                DatePicker("Date & Time", selection: $taskDate)
 
                Toggle("Add to Calendar", isOn: $addToCalendar)
                    .tint(Color(hex: "7C6FF7"))
 
                Section {
                    Toggle("Remind me", isOn: $setReminder)
                        .tint(Color(hex: "7C6FF7"))
                    if setReminder {
                        DatePicker("Reminder time", selection: $reminderDate, in: Date()...)
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
 
    private func saveTask() {
        let task = TaskItem(title: title, date: taskDate, isCompleted: false)
        if setReminder {
            task.reminderDate = reminderDate
        }
        modelContext.insert(task)
 
        if addToCalendar {
            Task {
                do {
                    try await calendarManager.saveTaskToCalendar(title: title, date: taskDate)
                } catch {
                    print("Calendar save error: \(error)")
                }
            }
        }
 
        if setReminder {
            NotificationManager.shared.scheduleNotification(for: task)
        }
        dismiss()
    }
}
 
struct EditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var task: TaskItem
    @State private var title: String
    @State private var taskDate: Date
    @State private var addToCalendar: Bool
    @State private var setReminder: Bool
    @State private var reminderDate: Date
    @State private var calendarManager = CalendarManager()

    init(task: TaskItem) {
        self.task = task
        _title = State(initialValue: task.title)
        _taskDate = State(initialValue: task.date)
        _addToCalendar = State(initialValue: false) // We don't track calendar sync, default false
        _setReminder = State(initialValue: task.reminderDate != nil)
        _reminderDate = State(initialValue: task.reminderDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                DatePicker("Date & Time", selection: $taskDate)

                Toggle("Add to Calendar", isOn: $addToCalendar)

                Section {
                    Toggle("Remind me", isOn: $setReminder)
                    if setReminder {
                        DatePicker("Reminder time", selection: $reminderDate, in: Date()...)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .environment(calendarManager)
    }

    private func saveChanges() {
        task.title = title
        task.date = taskDate
        if task.reminderDate != nil {
            NotificationManager.shared.cancelNotification(for: task)
        }
        if setReminder {
            task.reminderDate = reminderDate
            NotificationManager.shared.scheduleNotification(for: task)
        } else {
            task.reminderDate = nil
        }
        try? modelContext.save()
        dismiss()
    }
}
