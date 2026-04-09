import SwiftUI
import SwiftData

@main
struct TasklyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Folder.self,
            Note.self,
            TaskItem.self,
            DrawingNote.self,
            Course.self,
            Home.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    _ = NotificationManager.shared
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
