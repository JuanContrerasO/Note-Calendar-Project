//
//  HomeView.swift
//  Taskly
//
//  Created by Ava Saltzman on 3/23/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query var notes: [Note]
    @Query var tasks: [TaskItem]
    @Query var courses: [Course]
    @Query var homeData: [Home]

    @Environment(\.modelContext) private var context

    var upcomingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted && $0.date >= Date() }
            .sorted { $0.date < $1.date }
    }

    var overdueTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted && $0.date < Date() }
    }

    var recentNotes: [Note] {
        notes.sorted { $0.createdAt > $1.createdAt }
    }

    var userName: String {
        homeData.first?.userName ?? "You"
    }

    var nextCourse: Course? {
        let now = Date()
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: now)
        let weekdaySymbol = shortWeekday(todayWeekday)

        return courses
            .filter { $0.daysOfWeek.contains(weekdaySymbol) && $0.startTime > now }
            .sorted { $0.startTime < $1.startTime }
            .first
    }

    var body: some View {
        ZStack {
            Color(hex: "0F1629").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greetingText())
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.2)
                            .foregroundColor(Color(hex: "5a6a8a"))
                        Text("\(userName) ✦")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(Color(hex: "e8edf5"))
                        Text(formattedToday())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "7C6FF7"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "1a2540"))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(hex: "2d3d60"), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    // MARK: - Next Up
                    sectionLabel("next up")

                    if let course = nextCourse {
                        nextClassCard(course: course)
                    } else {
                        emptyNextClass()
                    }

                    // MARK: - Overview
                    sectionLabel("overview")

                    HStack(spacing: 10) {
                        overviewCard(icon: "✦", color: "7C6FF7", label: "tasks",   count: "\(upcomingTasks.count)")
                        overviewCard(icon: "◈", color: "2DD4BF", label: "notes",   count: "\(notes.count)")
                        overviewCard(icon: "◎", color: "E24B4A", label: "overdue", count: "\(overdueTasks.count)")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // MARK: - Recent Notes
                    if !recentNotes.isEmpty {
                        sectionLabel("recent notes")
                        VStack(spacing: 8) {
                            ForEach(recentNotes.prefix(3)) { note in
                                noteRow(title: note.title, sub: relativeDate(note.createdAt))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }

                    // MARK: - Upcoming Tasks
                    if !upcomingTasks.isEmpty {
                        sectionLabel("due soon")
                        VStack(spacing: 8) {
                            ForEach(upcomingTasks.prefix(3)) { task in
                                taskRow(task)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
    }

    // MARK: - Sub Views
    func nextClassCard(course: Course) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("next class")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.0)
                .foregroundColor(.white.opacity(0.65))
            Text(course.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("\(formatTime(course.startTime)) — \(course.location)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
            if !course.instructor.isEmpty {
                Text(course.instructor)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "7C6FF7"))
        .cornerRadius(18)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    func emptyNextClass() -> some View {
        Text("no more classes today")
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "5a6a8a"))
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "161f35"))
            .cornerRadius(18)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
    }

    func taskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Button {
                task.isCompleted.toggle()
            } label: {
                Circle()
                    .stroke(Color(hex: task.isCompleted ? "2DD4BF" : "3a4a6a"), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .fill(task.isCompleted ? Color(hex: "2DD4BF") : Color.clear)
                            .frame(width: 10, height: 10)
                    )
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: task.isCompleted ? "4a5a7a" : "c8d3e8"))
                    .strikethrough(task.isCompleted)
                Text("Due \(formatDate(task.date))")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "4a5a7a"))
            }
            Spacer()
            if task.date < Date() {
                Text("overdue")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "E24B4A"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: "E24B4A").opacity(0.12))
                    .cornerRadius(10)
            } else {
                Text(daysUntil(task.date))
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "fbbf24"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: "fbbf24").opacity(0.10))
                    .cornerRadius(10)
            }
        }
        .padding(12)
        .background(Color(hex: "161f35"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1e2c45"), lineWidth: 0.5))
    }

    func noteRow(title: String, sub: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "7C6FF7"))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "c8d3e8"))
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "4a5a7a"))
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "161f35"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1e2c45"), lineWidth: 0.5))
    }

    func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .tracking(1.2)
            .foregroundColor(Color(hex: "5a6a8a"))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }

    func overviewCard(icon: String, color: String, label: String, count: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(icon)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: color))
                .frame(width: 28, height: 28)
                .background(Color(hex: color).opacity(0.15))
                .cornerRadius(8)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "5a6a8a"))
            Text(count)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "e8edf5"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "161f35"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1e2c45"), lineWidth: 0.5))
    }

    // MARK: - Formatters
    func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "good morning"
        case 12..<17: return "good afternoon"
        default:      return "good evening"
        }
    }

    func formattedToday() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE · MMMM d"
        return f.string(from: Date())
    }

    func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    func relativeDate(_ date: Date) -> String {
        let diff = Calendar.current.dateComponents([.hour, .day], from: date, to: Date())
        if let hours = diff.hour, hours < 24 { return hours == 0 ? "just now" : "updated \(hours)h ago" }
        if let days = diff.day { return days == 1 ? "updated yesterday" : "updated \(days)d ago" }
        return "updated recently"
    }

    func daysUntil(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return days == 0 ? "today" : "\(days)d"
    }

    func shortWeekday(_ weekday: Int) -> String {
        ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][weekday]
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Note.self, TaskItem.self, Course.self, Home.self, DrawingNote.self])
}
