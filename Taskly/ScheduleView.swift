import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [Course]
    @State private var showingAddCourse = false

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
            }
        }
    }

    func deleteCourse(at offsets: IndexSet) {
        for index in offsets {
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

    let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

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
            }
            .navigationTitle("New Course")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
                        modelContext.insert(course)
                        dismiss()
                    }
                    .disabled(name.isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }
}

struct CourseDetailView: View {
    let course: Course

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
        }
        .navigationTitle(course.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
