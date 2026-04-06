import Foundation
import SwiftData
import PencilKit

@Model
final class Folder {
    var name: String
    var createdAt: Date
    var colorName: String
    @Relationship var notes: [Note] = []

    init(name: String, createdAt: Date, colorName: String = "blue") {
        self.name = name
        self.createdAt = createdAt
        self.colorName = colorName
    }
}

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    @Relationship(inverse: \Folder.notes) var folder: Folder?

    init(title: String, content: String, createdAt: Date, folder: Folder? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.folder = folder
    }
}

@Model
final class TaskItem {
    var title: String
    var date: Date
    var isCompleted: Bool

    init(title: String, date: Date, isCompleted: Bool) {
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
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
