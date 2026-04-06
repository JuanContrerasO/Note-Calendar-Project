import Foundation
import EventKit

@Observable
class CalendarManager {
    var events: [EKEvent] = []
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var errorMessage: String?

    private let eventStore = EKEventStore()

    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                if !granted {
                    self.errorMessage = "Calendar access was denied. You can enable it in Settings."
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to request calendar access: \(error.localizedDescription)"
            }
        }
    }

    func fetchEvents(for date: Date) {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            events = []
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        events = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }

    func saveTaskToCalendar(title: String, date: Date) async throws {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            throw CalendarError.noAccess
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: date)!
        event.calendar = eventStore.defaultCalendarForNewEvents

        try eventStore.save(event, span: .thisEvent)
    }

    // MARK: - Course Calendar Integration

    func createEvent(for course: Course) async throws -> String {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            throw CalendarError.noAccess
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = course.name
        event.location = course.location
        event.notes = "Instructor: \(course.instructor)"

        // Find the next occurrence of this course
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute], from: course.startTime)

        let daysArray = course.daysOfWeek.components(separatedBy: ", ").compactMap { dayString -> EKWeekday? in
            switch dayString {
            case "Sun": return .sunday
            case "Mon": return .monday
            case "Tue": return .tuesday
            case "Wed": return .wednesday
            case "Thu": return .thursday
            case "Fri": return .friday
            case "Sat": return .saturday
            default: return nil
            }
        }

        guard !daysArray.isEmpty else { throw CalendarError.invalidDate }

        var nextStartDate: Date? = nil
        for daysToAdd in 0...14 {
            guard let candidate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: candidate)
            let ekWeekday = EKWeekday(rawValue: weekday)
            if daysArray.contains(ekWeekday) {
                var components = calendar.dateComponents([.year, .month, .day], from: candidate)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                if let startDate = calendar.date(from: components), startDate > now {
                    nextStartDate = startDate
                    break
                }
            }
        }

        guard let startDate = nextStartDate else { throw CalendarError.invalidDate }

        event.startDate = startDate
        let duration = course.endTime.timeIntervalSince(course.startTime)
        event.endDate = startDate.addingTimeInterval(duration)

        let ekDays = daysArray.map { EKRecurrenceDayOfWeek($0) }
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            daysOfTheWeek: ekDays,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,      // 👈 Required parameter
            daysOfTheYear: nil,
            setPositions: nil,
            end: nil
        )
        event.addRecurrenceRule(recurrenceRule)

        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .futureEvents)
        return event.eventIdentifier
    }

    func updateEvent(for course: Course) async throws -> String {
        guard let eventID = course.calendarEventID,
            let event = eventStore.event(withIdentifier: eventID) else {
            throw CalendarError.eventNotFound
        }
        try eventStore.remove(event, span: .futureEvents)
        let newEventID = try await createEvent(for: course)
        return newEventID
    }

    func deleteEvent(for course: Course) async throws {
        guard let eventID = course.calendarEventID,
            let event = eventStore.event(withIdentifier: eventID) else {
            return
        }
        try eventStore.remove(event, span: .futureEvents)
    }

    enum CalendarError: LocalizedError {
        case noAccess
        case invalidDate
        case eventNotFound

        var errorDescription: String? {
            switch self {
            case .noAccess: return "Calendar access is required."
            case .invalidDate: return "Could not create a valid start date."
            case .eventNotFound: return "Calendar event not found."
            }
        }
    }
}
