import Foundation

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var createdAt: Date
}

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date
    var isCompleted: Bool
}
struct Msgs: Identifiable, Codable {
    var id = UUID()
    var title: String
    var msg: Date
    var isCompleted: String
}




