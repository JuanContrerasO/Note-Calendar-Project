import SwiftUI

struct ContentView: View {
    @AppStorage("isWelcomeSheetShowing") private var isWelcomeSheetShowing = true

    var body: some View {
        TabView {
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            DrawingNotesView()
                .tabItem {
                    Label("Draw", systemImage: "pencil.tip.crop.circle")
                }

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "book")
                }
        }
        .onAppear {
            _ = NotificationManager.shared
        }
        .sheet(isPresented: $isWelcomeSheetShowing) {
            WelcomeSheetView(isPresented: $isWelcomeSheetShowing)
                //For ipad (and other devices): the sheet displays in medium or large sizes dependig on the device being used
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct WelcomeSheetView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Image("Image")
                .resizable()
                .scaledToFill()
                .opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Welcome to Taskly!")
                    .font(.largeTitle)
                    .bold()
                Text("Manage your notes and calendar in one place.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Get Started") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
