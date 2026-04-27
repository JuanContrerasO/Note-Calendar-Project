import Foundation
import SwiftData
import PencilKit

@Model
final class Folder {
    var name: String
    var createdAt: Date
    var colorName: String
    var sortOrder: Int
    @Attribute(.unique) var id: UUID
    @Relationship var notes: [Note] = []

    init(name: String, createdAt: Date, colorName: String = "blue", sortOrder: Int = 0) {
        self.name = name
        self.createdAt = createdAt
        self.colorName = colorName
        self.sortOrder = sortOrder
        self.id = UUID()
    }
}

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var sortOrder: Int
    @Relationship(inverse: \Folder.notes) var folder: Folder?

    init(title: String, content: String, createdAt: Date, folder: Folder? = nil, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.folder = folder
        self.sortOrder = sortOrder
    }
}

@Model
final class TaskItem {
    @Attribute(.unique) var id = UUID()
    var title: String
    var date: Date
    var isCompleted: Bool
    var reminderDate: Date?

    init(title: String, date: Date, isCompleted: Bool, reminderDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.reminderDate = reminderDate
    }
}

@Model
final class DrawingNote {
    var title: String
    @Attribute(.externalStorage) var drawingData: Data
    var createdAt: Date

    init(title: String, drawingData: Data, createdAt: Date) {
        self.title = title
        self.drawingData = drawingData
        self.createdAt = createdAt
    }
}

@Model
final class Course {
    var name: String
    var instructor: String
    var location: String
    var daysOfWeek: String
    var startTime: Date
    var endTime: Date
    var calendarEventID: String?

    init(name: String, instructor: String, location: String, daysOfWeek: String, startTime: Date, endTime: Date, calendarEventID: String? = nil) {
        self.name = name
        self.instructor = instructor
        self.location = location
        self.daysOfWeek = daysOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.calendarEventID = calendarEventID
    }
}

@Model
final class Home {
    var userName: String
    var createdAt: Date
    init(userName: String, createdAt: Date = .now) {
        self.userName = userName
        self.createdAt = createdAt
    }
}
