import SwiftUI
import SwiftData

struct EditCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var course: Course
    @State private var calendarManager = CalendarManager()
    @State private var name: String
    @State private var instructor: String
    @State private var location: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedDays: Set<String>
    @State private var syncToCalendar: Bool
    @State private var isShowingError = false
    @State private var errorMessage = ""

    let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    init(course: Course) {
        self.course = course
        _name = State(initialValue: course.name)
        _instructor = State(initialValue: course.instructor)
        _location = State(initialValue: course.location)
        _startTime = State(initialValue: course.startTime)
        _endTime = State(initialValue: course.endTime)
        let daysArray = course.daysOfWeek.components(separatedBy: ", ")
        _selectedDays = State(initialValue: Set(daysArray.filter { !$0.isEmpty }))
        _syncToCalendar = State(initialValue: course.calendarEventID != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Course Info") {
                    TextField("Course Name", text: $name)
                    TextField("Instructor", text: $instructor)
                    TextField("Location / Room", text: $location)
                }
                Section("Days") {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Button(action: {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }) {
                            HStack {
                                Text(day).foregroundColor(.primary)
                                Spacer()
                                if selectedDays.contains(day) {
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                Section("Time") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                Section {
                    Toggle("Sync to Calendar", isOn: $syncToCalendar)
                }
            }
            .navigationTitle("Edit Course")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(name.isEmpty || selectedDays.isEmpty)
                }
            }
            .alert("Error", isPresented: $isShowingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .environment(calendarManager)
    }

    private func saveChanges() {
        let sortedDays = daysOfWeek.filter { selectedDays.contains($0) }
        let daysString = sortedDays.joined(separator: ", ")
        
        course.name = name
        course.instructor = instructor
        course.location = location
        course.startTime = startTime
        course.endTime = endTime
        course.daysOfWeek = daysString

        let oldSyncEnabled = course.calendarEventID != nil

        if syncToCalendar && !oldSyncEnabled {
            // Add to calendar
            Task {
                do {
                    let eventID = try await calendarManager.createEvent(for: course)
                    await MainActor.run {
                        course.calendarEventID = eventID
                        try? modelContext.save()
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to sync: \(error.localizedDescription)"
                        isShowingError = true
                    }
                }
            }
        } else if !syncToCalendar && oldSyncEnabled {
            // Remove from calendar
            Task {
                do {
                    try await calendarManager.deleteEvent(for: course)
                    await MainActor.run {
                        course.calendarEventID = nil
                        try? modelContext.save()
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to remove from calendar: \(error.localizedDescription)"
                        isShowingError = true
                    }
                }
            }
        } else if syncToCalendar && oldSyncEnabled {
            // Update calendar event
            Task {
                do {
                    let newEventID = try await calendarManager.updateEvent(for: course)
                    await MainActor.run {
                        course.calendarEventID = newEventID
                        try? modelContext.save()
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to update calendar: \(error.localizedDescription)"
                        isShowingError = true
                    }
                }
            }
        } else {
            // No calendar change
            try? modelContext.save()
            dismiss()
        }
    }
}