import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [Course]
    @State private var showingAddCourse = false
    @State private var calendarManager = CalendarManager()

    var body: some View {
        NavigationStack {
            List {
                ForEach(courses) { course in
                    NavigationLink(destination: CourseDetailView(course: course)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.name)
                                .font(.headline)
                            Text(course.daysOfWeek)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            HStack {
                                Text(course.startTime, style: .time)
                                Text("-")
                                Text(course.endTime, style: .time)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteCourse)
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddCourse = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCourse) {
                AddCourseView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .environment(calendarManager)
    }

    func deleteCourse(at offsets: IndexSet) {
        for index in offsets {
            let course = courses[index]
            if course.calendarEventID != nil {
                Task {
                    try? await calendarManager.deleteEvent(for: course)
                }
            }
            modelContext.delete(courses[index])
        }
    }
}

struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var instructor = ""
    @State private var location = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedDays: Set<String> = []
    @State private var syncToCalendar = true
    @State private var isShowingError = false
    @State private var errorMessage = ""

    let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    @Environment(CalendarManager.self) private var calendarManager

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
                                Text(day)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedDays.contains(day) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
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
            .navigationTitle("New Course")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCourse() }
                        .disabled(name.isEmpty || selectedDays.isEmpty)
                }
            }
            .alert("Error", isPresented: $isShowingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveCourse() {
        let sortedDays = daysOfWeek.filter { selectedDays.contains($0) }
        let daysString = sortedDays.joined(separator: ", ")
        let course = Course(
            name: name,
            instructor: instructor,
            location: location,
            daysOfWeek: daysString,
            startTime: startTime,
            endTime: endTime
        )

        if syncToCalendar {
            Task {
                do {
                    try await calendarManager.requestAccess()
                    let eventID = try await calendarManager.createEvent(for: course)
                    await MainActor.run {
                        course.calendarEventID = eventID
                        modelContext.insert(course)
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to sync: \(error.localizedDescription)"
                        isShowingError = true
                        // Do NOT insert the course
                    }
                }
            }
        } else {
            modelContext.insert(course)
            dismiss()
        }
    }
}

struct CourseDetailView: View {
    let course: Course
    @Environment(CalendarManager.self) private var calendarManager
    @State private var syncEnabled: Bool
    @State private var isShowingError = false
    @State private var errorMessage = ""
    @State private var isSyncing = false
    @State private var showingEditSheet = false

    init(course: Course) {
        self.course = course
        _syncEnabled = State(initialValue: course.calendarEventID != nil)
    }

    var body: some View {
        List {
            Section("Course Info") {
                LabeledContent("Course", value: course.name)
                LabeledContent("Instructor", value: course.instructor)
                LabeledContent("Location", value: course.location)
            }
            Section("Schedule") {
                LabeledContent("Days", value: course.daysOfWeek)
                HStack {
                    Text("Time")
                    Spacer()
                    Text(course.startTime, style: .time)
                    Text("-")
                    Text(course.endTime, style: .time)
                }
            }
            Section {
                Toggle("Sync to Calendar", isOn: $syncEnabled)
                    .onChange(of: syncEnabled) { _, newValue in
                        Task { await toggleSync(enable: newValue) }
                    }
                if syncEnabled && course.calendarEventID != nil {
                    Button("Force Re-sync", role: .none) {
                        Task { await forceResync() }
                    }
                    .disabled(isSyncing)
                }
            }
        }
        .navigationTitle(course.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCourseView(course: course)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Error", isPresented: $isShowingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .overlay { if isSyncing { ProgressView() } }
    }

    // Keep the existing toggleSync and forceResync methods unchanged
    private func toggleSync(enable: Bool) async {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try await calendarManager.requestAccess()
            if enable {
                if course.calendarEventID == nil {
                    let eventID = try await calendarManager.createEvent(for: course)
                    await MainActor.run {
                        course.calendarEventID = eventID
                    }
                }
            } else {
                if course.calendarEventID != nil {
                    try await calendarManager.deleteEvent(for: course)
                    await MainActor.run {
                        course.calendarEventID = nil
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isShowingError = true
                syncEnabled = course.calendarEventID != nil
            }
        }
    }

    private func forceResync() async {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let newEventID = try await calendarManager.updateEvent(for: course)
            await MainActor.run {
                course.calendarEventID = newEventID
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
