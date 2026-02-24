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

    enum CalendarError: LocalizedError {
        case noAccess

        var errorDescription: String? {
            switch self {
            case .noAccess:
                return "Calendar access is required to save events."
            }
        }
    }
}
