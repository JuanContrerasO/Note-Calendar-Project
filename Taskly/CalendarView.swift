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

                if let errorMessage = calendarManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                List {
                    if !calendarManager.events.isEmpty {
                        Section("Calendar Events") {
                            ForEach(calendarManager.events, id: \.eventIdentifier) { event in
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text(event.title)
                                            .font(.body)
                                        if let startDate = event.startDate {
                                            Text(startDate, style: .time)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Section("Tasks") {
                        ForEach(filteredTasks) { task in
                            HStack {
                                Button(action: { toggleTask(task) }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.isCompleted ? .green : .gray)
                                }

                                VStack(alignment: .leading) {
                                    Text(task.title)
                                        .strikethrough(task.isCompleted)
                                    Text(task.date, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onDelete(perform: deleteTask)
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddTask, onDismiss: {
                calendarManager.fetchEvents(for: selectedDate)
            }) {
                AddTaskView(selectedDate: selectedDate, calendarManager: calendarManager)
            }
            .onAppear {
                Task {
                    await calendarManager.requestAccess()
                    calendarManager.fetchEvents(for: selectedDate)
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
    }

    func deleteTask(at offsets: IndexSet) {
        let filtered = filteredTasks
        for index in offsets {
            modelContext.delete(filtered[index])
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
    @State private var addToCalendar = false

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

                if EKEventStore.authorizationStatus(for: .event) == .fullAccess {
                    Toggle("Add to Calendar", isOn: $addToCalendar)
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let task = TaskItem(title: title, date: taskDate, isCompleted: false)
                        modelContext.insert(task)

                        if addToCalendar {
                            Task {
                                try? await calendarManager.saveTaskToCalendar(title: title, date: taskDate)
                            }
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
