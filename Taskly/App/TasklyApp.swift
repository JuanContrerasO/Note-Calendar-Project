//
//  TasklyApp.swift
//  Taskly
//
//  Created by Ava Saltzman on 2/5/26.
//

import SwiftUI
import SwiftData

@main
struct TasklyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Note.self,
            TaskItem.self,
            DrawingNote.self,
            Course.self,
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
        }
        .modelContainer(sharedModelContainer)
    }
}
