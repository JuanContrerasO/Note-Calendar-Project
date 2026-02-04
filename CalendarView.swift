import SwiftUI

struct CalendarView: View {
    @State private var tasks: [Task] = []
    @State private var showingAddTask = false
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                List {
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
            .navigationTitle("Calendar")
            .toolbar {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(tasks: $tasks, selectedDate: selectedDate)
            }
        }
    }
    
    var filteredTasks: [Task] {
        tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date < $1.date }
    }
    
    func toggleTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { filteredTasks[$0] }
        tasks.removeAll { task in tasksToDelete.contains { $0.id == task.id } }
    }
}

struct AddTaskView: View {
    @Binding var tasks: [Task]
    let selectedDate: Date
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var taskDate: Date
    
    init(tasks: Binding<[Task]>, selectedDate: Date) {
        self._tasks = tasks
        self.selectedDate = selectedDate
        self._taskDate = State(initialValue: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Task Title", text: $title)
                DatePicker("Date & Time", selection: $taskDate)
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let task = Task(title: title, date: taskDate, isCompleted: false)
                        tasks.append(task)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
