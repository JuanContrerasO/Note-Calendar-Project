import SwiftUI

struct ContentView: View {
    
    @AppStorage("isWelcomeSheetShowing") var isWelcomeSheetShowing = true
    
    
    
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
                .sheet(isPresented: $isWelcomeSheetShowing) {
                    VStack(spacing: 20) {
                        Text("Welcome to Taskly!")
                            .font(.largeTitle)
                            .bold()
                        Text("Manage your notes and calendar in one place.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Get Started") {
                            isWelcomeSheetShowing = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
           
            
        }
    }
}

#Preview {
    ContentView()
}
