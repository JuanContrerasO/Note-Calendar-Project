import Foundation
import SwiftData
import PencilKit

@Model
final class Note {
    var title: String
    var content: String
    var createdAt: Date

    init(title: String, content: String, createdAt: Date) {
        self.title = title
        self.content = content
        self.createdAt = createdAt
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

    init(name: String, instructor: String, location: String, daysOfWeek: String, startTime: Date, endTime: Date) {
        self.name = name
        self.instructor = instructor
        self.location = location
        self.daysOfWeek = daysOfWeek
        self.startTime = startTime
        self.endTime = endTime
    }
}
